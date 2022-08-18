if !has('python3')
    return
endif

let s:selection_window_path = expand('<sfile>:p:h')

python3 << EOF
import vim
import sys
sys.path.append(vim.eval('s:selection_window_path'))
import vim_selection_window
EOF


function! Buffers()
python3 vim_selection_window.selection_window(vim_selection_window.BufferList())
endfunction

function! Files()
python3 vim_selection_window.selection_window(vim_selection_window.FileList())
endfunction

function! GitFiles()
python3 vim_selection_window.selection_window(vim_selection_window.GitTreeList())
endfunction
