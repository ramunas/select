vim9script

def Grep(grep: string, GrepCmd: func(string): string)
    execute 'syntax match Search |' .. grep .. '|'
    syntax match Type /^.\{-} /
    syntax match StatusLine /\<\d\{-}\>/

    var cmd = GrepCmd(grep)
    var grep_res = systemlist(cmd)

    b:grep_list = mapnew(grep_res, (_, x) => {
        var info = split(x, ':')
        var file = info[0]
        var line = info[1]
        var rest = info[2 : ]
        return [file, line, join(rest, ':')]
    })
enddef

def List(pattern: string): list<dict<any>>
    var pat = glob2regpat('*' .. pattern .. '*')
    var res = filter(copy(b:grep_list), (_, x) => x[0] =~ pat || x[2] =~ pat)

    var file_col_size = max(mapnew(res, (_, x) => len(x[0])))
    var file_num_col_size = max(mapnew(res, (_, x) => len(x[1])))

    return mapnew(res, (_, x): dict<any> => (
        {
                view: () =>
                    printf('%-' .. file_col_size ..
                        's %' .. file_num_col_size .. 's %s', x[0], x[1], x[2]),
                select: (() => {
                    execute 'edit' x[0]
                    execute ':' x[1]
                })
        }))
enddef

import "./select2.vim" as sel

def GrepList(grep: string, GrepCmd: func(string): string)
    sel.ShowSelectionWindow(List, () => Grep(grep, GrepCmd))
enddef

var GrepCurDir = (grep) => 'grep -d skip -n "' .. grep .. '" *'
var GrepCurDirRec = (grep) => 'grep -r -n "' .. grep .. '" *'
var GitGrep = (grep) => 'git grep -n "' .. grep .. '"'
var GitGrepRoot = (grep) => 'git grep -n "' .. grep .. '" "$(git rev-parse --show-toplevel)"'

command! -nargs=1 ShowGrepList GrepList('<args>', GrepCurDir)
command! -nargs=1 ShowGrepRecList GrepList('<args>', GrepCurDirRec)
command! -nargs=1 ShowGitGrepList GrepList('<args>', GitGrep)
command! -nargs=1 ShowGitGrepRootList GrepList('<args>', GitGrepRoot)

