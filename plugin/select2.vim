vim9script

def SelectionPromptOnChange()
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
    var Sel = b:selection_matches[line]['select']
    var sel_win = b:selection_window

    # execute selection action in the context of the original window
    execute ':' b:initial_window 'wincmd w'
    Sel()
    execute ':' sel_win 'wincmd w'
enddef

def BufferListSelection(pattern: string): list<dict<any>>
    var buf_list = getbufinfo({buflisted: 1})

    var reg_pattern = glob2regpat('*' .. pattern .. '*')
    buf_list = filter(buf_list, (_, b) => (bufname(b['bufnr']) =~ reg_pattern))

    var l = mapnew(buf_list, (_, x): dict<any> => (
        {
                view: (() => bufname(x['bufnr'])),
                select: (() => {
                    execute 'buffer' x['bufnr']
                })
        }))
    return l
enddef

def ShowSelectionWindow(Match: func(string): list<dict<any>>)
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

    autocmd TextChanged <buffer> SelectionPromptOnChange()
    autocmd TextChangedI <buffer> SelectionPromptOnChange()

    map <silent> <buffer> q :close<cr>
    map <silent> <buffer> <Enter> <ScriptCmd>SelectionSelect()<cr>
    imap <silent> <buffer> <Enter> <c-o>:call <ScriptCmd>SelectionSelect()<cr>

    startinsert
enddef

command ShowSelection ShowSelectionWindow(BufferListSelection)
