vim9script

def NewPanel()
    botright new
    setlocal nobuflisted nomodified buftype=nofile bufhidden=wipe
enddef

var callbacks = {}

export def ShowSelectionWindow()
    var inital_window = winnr()
    var initial_buffer = bufnr()

    var windows = getwininfo()

    NewPanel()
    var buf = bufnr()
    var win = winnr() 
    setlocal cursorline nowrap filetype=Select

    # TODO: do here syntax highlight

    # var Text_changed = () => {
    #     echo 'Changed'
    #     }

    # autocmd TextChanged <buffer> Text_changed()
    # autocmd TextChangedI <buffer> CallLambda(Text_changed)()
    # execute 'autocmd TextChangedI <buffer>' Text_changed '()'
enddef

command ShowSelection ShowSelectionWindow()
