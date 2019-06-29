" :py print "Hello"               # displays a message
" :py vim.command(cmd)            # execute an Ex command
" :py w = vim.windows[n]          # gets window "n"
" :py cw = vim.current.window     # gets the current window
" :py b = vim.buffers[n]          # gets buffer "n"
" :py cb = vim.current.buffer     # gets the current buffer
" :py w.height = lines            # sets the window height
" :py w.cursor = (row, col)       # sets the window cursor position
" :py pos = w.cursor              # gets a tuple (row, col)
" :py name = b.name               # gets the buffer file name
" :py line = b[n]                 # gets a line from the buffer
" :py lines = b[n:m]              # gets a list of lines
" :py num = len(b)                # gets the number of lines
" :py b[n] = str                  # sets a line in the buffer
" :py b[n:m] = [str1, str2, str3] # sets a number of lines at once
" :py del b[n]                    # deletes a line
" :py del b[n:m]                  # deletes a number of lines

python3 << EOF
from vim import *
import fnmatch
import itertools
import os.path


__callbacks__ = []
def add_callback(action):
    global __callbacks__
    __callbacks__.append(action)
    return len(__callbacks__) - 1

def call_callback(idx):
    global __callbacks__
    __callbacks__[idx]()

def call_callback_text(idx):
    return "call_callback(%d)" % idx
    

def map_normal_key(key, action):
    i = add_callback(action)
    command("map <silent> <buffer> %s :python3 %s<cr>" % (key, call_callback_text(i)))

def map_insert_key(key, action):
    i = add_callback(action)
    command("imap <silent> <buffer> %s <C-O>:python3 %s<cr>" % (key, call_callback_text(i)))

def add_event_listener(event, action):
    i = add_callback(action)
    command("autocmd %s <buffer> python3 %s" % (event, call_callback_text(i)))

def new_panel():
    command("botright new")
    # hidden 
    command("setlocal nobuflisted nomodified buftype=nofile bufhidden=wipe")


def start_insert_after_cursor():
    (line,col) = current.window.cursor
    chars = len(current.buffer[line - 1])
    if col == chars - 1:
        command('startinsert!')
    else:
        current.window.cursor = (line, col+1)
        command('startinsert')


def test_list_source():
    class E:
        def __init__(self,s):
            self.s = s
        def match(self):
            return self.s
        def view(self):
            return self.s
        def on_select(self):
            print (self.s, " selected")

    return ( E(x) for x in test_list )


def buffers():
    buffers = [ b for b in vim.buffers if b.options["buflisted"] ]

    # list the alt buf first
    alt = saved_state['alternate_buf_number']
    buffers = [ b for b in buffers if b.number == alt ] + [ b for b in buffers if b.number != alt ]

    def buf_name(b):
        name = vim.eval('bufname(%d)' % b.number)
        if b.options['buftype'] == b'':
            return os.path.basename(name)
        return name

    num_columns = 5
    columns = [ 
        [
            buf_name(b),
            '[+]' if b.options['modified'] else '[ ]',
            str(b.number),
            '[%s]' % b.options['filetype'].decode('utf-8'),
            b.name,
        ] for b in buffers ]

    widths = [
        max( [ len(columns[j][i]) for j in range(len(columns)) ] )
        for i in range(num_columns)
    ]

    format_pattern = ' '.join([ '%-' + str(widths[i]) + 's' for i in range(num_columns)])

    class E:
        def __init__(self,idx):
            self.i = idx
            self.name = buf_name(buffers[self.i])
        def match(self):
            return self.name
        def view(self): 
            return format_pattern % tuple(columns[self.i])
        def on_select(self):
            current.buffer = buffers[self.i]

    return [ E(i) for i in range(len(buffers)) ]


saved_state = {}

def selection_window(source):
    initial_window = current.window
    initial_buffer = current.buffer

    def dismiss():
        if (len(vim.windows) == 1):
            current.buffer = initial_buffer
        else:
            if initial_window in vim.windows and initial_window.buffer == initial_buffer:
                command("q")
                vim.current.window = initial_window
            else:
                # FIXME buffer might no longer exists. What to do in this case then depends on application.
                current.buffer = initial_buffer

    saved_state['alternate_buf_number'] = int(vim.eval('bufnr("#")'))

    new_panel()
    command('setlocal cursorline')
    command('setlocal nowrap')

    b = current.buffer
    w = current.window

    b[0] = ''

    def match_glob_pattern(pattern, string):
        return fnmatch.fnmatch(string.lower(), '*' + pattern.lower() + '*')

    matched = [None]
    def match(s):
        matched[0] = [x for x in source() if match_glob_pattern(s, x.match())]
        b[1:] = [ x.view() for x in matched[0] ]

    def text_changed():
        line = b[0].strip()
        match(line)
        if w.cursor[0] > 1: w.cursor = (1, len(b[0]))

    add_event_listener('TextChanged', text_changed)
    add_event_listener('TextChangedI', text_changed)


    def select():
        line = w.cursor[0]
        selected = (2 if line == 1 else line) - 2
        if len(matched[0]) > 0:
            dismiss()
            matched[0][selected].on_select()
        else:
            print("Not matches found for the query")

    map_normal_key('<Enter>', select)
    map_insert_key('<Enter>', select)

    map_normal_key("q", dismiss)

    # start_insert_after_cursor()
EOF


function! Buffers()
python3 << EOF
# selection_window(test_list_source)
selection_window(buffers)
EOF
endfunction


