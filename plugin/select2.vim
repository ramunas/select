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

    if len(b:selection_matches) == 0
        return
    endif

    var Sel = b:selection_matches[line]['select']
    var sel_win = b:selection_window

    b:selection_keep_open = false
    var wd = getcwd()
    # execute selection action in the context of the original window
    execute ':' b:initial_window 'wincmd w'
    execute 'cd' wd
    w:selection_window = sel_win
    Sel()
    execute ':' sel_win 'wincmd w'
    if b:selection_keep_open
        setline(1, '')
        SelectionPromptOnChange()
    else
        wincmd c
        stopinsert
    endif
enddef

def SelectionSelectAll()
    var Sel = b:selection_matches
    var init_win = b:initial_window
    var sel_win = b:selection_window
    var wd = getcwd()

    for match in Sel
        execute ':' init_win 'wincmd w'
        execute 'cd' wd
        match['select']()
        execute ':' sel_win 'wincmd w'
    endfor

    wincmd c
    stopinsert
enddef


def SelectionWindowClosed()
    execute ':' b:initial_window 'wincmd w'
enddef

def IgnoreTextChangeEvent()
    b:ignore_text_changed_event = true
enddef

export def ShowSelectionWindow(Match: func(string): list<dict<any>>, Init: func())
    var initial_window = winnr()
    var initial_buffer = bufnr()
    var alternate_buffer = bufnr('#')

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
    b:alternate_buffer = alternate_buffer

    autocmd TextChanged <buffer> SelectionPromptOnChange()
    autocmd TextChangedI <buffer> SelectionPromptOnChange()
    autocmd WinClosed <buffer> SelectionWindowClosed()

    # entering and leaving the insert mode, causes fireing of TextChanged.
    # Thus, it needs to be ignored in order not to rematch and redraw.
    autocmd InsertLeave <buffer> IgnoreTextChangeEvent()
    autocmd InsertEnter <buffer> IgnoreTextChangeEvent()

    map <silent> <buffer> q :close<cr>
    map <silent> <buffer> <cr> <ScriptCmd>SelectionSelect()<cr>
    map <silent> <buffer> ga <ScriptCmd>SelectionSelectAll()<cr>
    inoremap <silent> <buffer> <cr> <c-o><ScriptCmd>SelectionSelect()<cr>
    map <silent> <buffer> <2-LeftMouse> <ScriptCmd>SelectionSelect()<cr>
    inoremap <silent> <buffer> <2-LeftMouse> <c-o>:<ScriptCmd>SelectionSelect()<cr>

    Init()

    setline(1, '')
    SelectionPromptOnChange()

    startinsert
enddef

def Nothing()
enddef

import "./bufferlist.vim" as that
command! ShowBufferSelection ShowSelectionWindow(that.BufferListSelection, that.BufferListInit)

