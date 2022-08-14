vim9script

def SelectionPromptOnChange()
    if b:ignore_text_changed_event
        b:ignore_text_changed_event = false
        return
    endif

    var pattern = getline(1)

    var pos = getcurpos()
    if pos[1] > 1
        pos[1] = 1
        setpos('.', pos)
    endif

    var matches = b:selection_match_function(pattern)
    b:selection_matches = matches
    var lines = mapnew(matches, (_, match) => (match['view'])())
    deletebufline(bufnr(), 2, '$')
    setline(2, lines)
enddef

def SelectionSelect()
    var line = getcurpos()[1] - 2
    if line < 0
        line = 0
    endif
    var Sel = b:selection_matches[line]['select']
    var sel_win = b:selection_window


    # execute selection action in the context of the original window
    execute ':' b:initial_window 'wincmd w'
    Sel()
    execute ':' sel_win 'wincmd w'
    wincmd c
    stopinsert
enddef

def BufferListSelection(pattern: string): list<dict<any>>
    var buf_list = getbufinfo({buflisted: 1})
    var Bname = (b) => fnamemodify(bufname(b['bufnr']), ':t')
    var Relpath = (n) => fnamemodify(n, ':.')

    var reg_pattern = glob2regpat('*' .. pattern .. '*')
    buf_list = filter(buf_list, (_, b) => (Bname(b) =~ reg_pattern))

    var max_width = max(mapnew(buf_list, (_, b) => len(Bname(b))))

    return mapnew(buf_list, (_, x): dict<any> => (
        {
                view: () =>
                    printf('%-' .. max_width .. 's %3d %s', Bname(x), x['bufnr'], Relpath(x['name'])),
                select: (() => {
                    execute 'buffer' x['bufnr']
                })
        }))
enddef

def BufferListInit()
    syntax match LineNr |\<[0-9]\+\>|
    syntax match Type |^.\{-} |
enddef

def SelectionWindowClosed()
    execute ':' b:initial_window 'wincmd w'
enddef

def IgnoreTextChangeEvent()
    b:ignore_text_changed_event = true
enddef

def ShowSelectionWindow(Match: func(string): list<dict<any>>, Init: func())
    var initial_window = winnr()
    var initial_buffer = bufnr()

    # open the selection pane
    botright new
    setlocal nobuflisted nomodified buftype=nofile bufhidden=wipe
    setlocal cursorline nowrap filetype=Select

    var buf = bufnr()
    var selection_window = winnr() 

    b:selection_match_function = Match
    b:initial_window = initial_window
    b:initial_buffer = initial_buffer
    b:selection_window = selection_window
    b:ignore_text_changed_event = false

    autocmd TextChanged <buffer> SelectionPromptOnChange()
    autocmd TextChangedI <buffer> SelectionPromptOnChange()
    autocmd WinClosed <buffer> SelectionWindowClosed()

    # entering and leaving the insert mode, causes fireing of TextChanged.
    # Thus, it needs to be ignored in order not to rematch and redraw.
    autocmd InsertLeave <buffer> IgnoreTextChangeEvent()
    autocmd InsertEnter <buffer> IgnoreTextChangeEvent()

    map <silent> <buffer> q :close<cr>
    map <silent> <buffer> <cr> <ScriptCmd>SelectionSelect()<cr>
    inoremap <silent> <buffer> <cr> <c-o>:<ScriptCmd>SelectionSelect()<cr><esc>
    map <silent> <buffer> <2-LeftMouse> <ScriptCmd>SelectionSelect()<cr>
    inoremap <silent> <buffer> <2-LeftMouse> <c-o>:<ScriptCmd>SelectionSelect()<cr><esc>

    Init()

    setline(1, '')
    SelectionPromptOnChange()

    startinsert
enddef

def Nothing()
enddef

command ShowSelection ShowSelectionWindow(BufferListSelection, BufferListInit)
