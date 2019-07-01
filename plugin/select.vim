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
    command("setlocal nobuflisted nomodified buftype=nofile bufhidden=wipe")


def start_insert_after_cursor():
    (line,col) = current.window.cursor
    chars = len(current.buffer[line - 1])
    if col == chars - 1:
        command('startinsert!')
    else:
        current.window.cursor = (line, col+1)
        command('startinsert')


class SelectionList(object):
    def entries(self):
        return []
    def syntax(self):
        pass
    def no_match_entries(self):
        pass


class BufferList(SelectionList):
    def entries(self):
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
                (lambda name: '(unnamed)' if name == '' else name) (buf_name(b)),
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


def lambda_obj(**d):
    return (type('', (object,), d))()


class FileList(SelectionList):
    def syntax(self):
        vim.command("syn match Title |^.*\.|")
        vim.command("syn match Directory |^.*/$|")
        vim.command("syn match SpecialKey |\[.*\]|")

    def entries(self):
        import os
        import os.path

        def partition(predicates, it):
            return tuple( (filter(p, it) for p in predicates ) )

        entries = [e for e in os.scandir('.') if not e.name.startswith('.')]

        part = partition( (lambda e: e.is_file(), lambda e: e.is_dir(), lambda e: not(e.is_file() or e.is_dir())), entries)
        sort_on_name = lambda e: e.name
        (files, dirs, others) = tuple(map(lambda entries: sorted(entries, key=sort_on_name), part))

        cwd = os.path.abspath(os.getcwd())

        file_list = (
            (lambda entry:
                lambda_obj(
                    dismiss   = not(entry.is_dir()),
                    match     = lambda s: entry.name,
                    view      = lambda s: '  ' + (entry.name + '/' if entry.is_dir() else entry.name),
                    on_select = lambda s: command("cd " + entry.name)
                                          if entry.is_dir()
                                          else command("edit " + os.path.join(cwd, entry.name))
                )) (e)
            for e in itertools.chain(files, dirs, others)
        )

        up_dir = [
            lambda_obj(
                dismiss = False,
                match = lambda s: '..',
                view = lambda s: '[.. up dir]',
                on_select = lambda s: command("cd .. ")
            ),
            lambda_obj(
                dismiss = False,
                match = lambda s: '',
                view = lambda s: '[working directory ' + cwd + ']',
                on_select = lambda s: None
            ),

            # lambda_obj(
            #     dismiss = False,
            #     match = lambda s: '..',
            #     view = lambda s: current_dir + ' (go back to)',
            #     on_select = lambda s: command("cd " + current_dir)
            # )
        ]

        # vim.command("hi match ")

        return itertools.chain(up_dir, file_list)


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
    command('set filetype=Select')

    b = current.buffer
    w = current.window

    source.syntax()

    b[0] = ''

    def match_glob_pattern(pattern, string):
        return fnmatch.fnmatch(string.lower(), '*' + pattern.lower() + '*')

    matched = [None]
    def match(s):
        matched[0] = [x for x in source.entries() if match_glob_pattern(s, x.match())]
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
            entry = matched[0][selected]
            dis = not(hasattr(entry, 'dismiss')) or entry.dismiss

            if dis: dismiss()

            entry.on_select()

            if not dis and b.number == current.buffer.number:
                # action was token on the buffer, so redo the matches
                b[0] = ''
                text_changed()
            else:
                vim.command("stopinsert")
        else:
            print("Not matches found for the query")

    map_normal_key('<Enter>', select)
    map_insert_key('<Enter>', select)

    map_normal_key("q", dismiss)

    start_insert_after_cursor()
EOF


function! Buffers()
python3 selection_window(BufferList())
endfunction

function! Files()
python3 selection_window(FileList())
endfunction

