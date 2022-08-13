vim9script

def SelectionPromptOnChange()
    var pattern = getline(1)
    var matches = b:selection_match_function(pattern)
    b:selection_matches = matches
    var lines = mapnew(matches, (_, match) => (match['view'])())
    setline(2, lines)
enddef

def SelectionSelect()
    var line = getcurpos()[1] - 2
    var Sel = b:selection_matches[line]['select']
    Sel()
enddef

def BufferListSelection(pattern: string): list<dict<any>>
    var buf_list = getbufinfo({buflisted: 1})
    var l = mapnew(buf_list, (_, x): dict<any> => (
        {
                view: (() => x['name']),
                select: (() => {
                    echo x['name']
                })
        }))
    return l
enddef

def ShowSelectionWindow(Match: func(string): list<dict<any>>)
    var inital_window = winnr()
    var initial_buffer = bufnr()

    var windows = getwininfo()

    botright new
    setlocal nobuflisted nomodified buftype=nofile bufhidden=wipe

    var buf = bufnr()
    var win = winnr() 
    setlocal cursorline nowrap filetype=Select

    b:selection_match_function = Match

    autocmd TextChanged <buffer> SelectionPromptOnChange()
    autocmd TextChangedI <buffer> SelectionPromptOnChange()

    map <silent> <buffer> q :close<cr>
    map <silent> <buffer> <Enter> <ScriptCmd>SelectionSelect()<cr>
    imap <silent> <buffer> <Enter> <c-o>:call <ScriptCmd>SelectionSelect()<cr>
enddef

command ShowSelection ShowSelectionWindow(BufferListSelection)
# command ShowSelection ShowSelectionWindow((x: string) => ['hello', 'world'])
