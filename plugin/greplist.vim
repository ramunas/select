vim9script

var GrepCurDir = (grep) => 'grep -d skip -n "' .. grep .. '" *'
var GrepCurDirRec = (grep) => 'grep -r -n "' .. grep .. '" *'

def Grep(grep: string, GrepCmd: func(string): string)
    execute 'syntax match Search |' .. grep .. '|'
    syntax match Type /^.\{-} /
    syntax match StatusLine /\<\d\{-}\>/

    var grep_res = systemlist(GrepCmd(grep))
    # var grep_res = systemlist('grep -d skip -n "' .. grep .. '" *')
    b:grep_list = mapnew(grep_res, (_, x) => {
        var info = split(x, ':')
        var file = info[0]
        var line = info[1]
        var rest = info[2 : ]
        return [file, line, join(rest, ':')]
    })
enddef

def Init(grep: string): func()
    return () => (Grep(grep))
enddef

def List(pattern: string): list<dict<any>>
    var pat = glob2regpat('*' .. pattern .. '*')
    var res = filter(copy(b:grep_list), (_, x) => x[0] =~ pat || x[2] =~ pat)

    var col_size = max(mapnew(res, (_, x) => len(x[0])))

    return mapnew(res, (_, x): dict<any> => (
        {
                view: () =>
                    printf('%-' .. col_size .. 's %3s %s', x[0], x[1], x[2]),
                select: (() => {
                    execute 'edit' x[0]
                    execute ':' x[1]
                })
        }))
enddef

import "./select2.vim" as sel
command! -nargs=1 ShowGrepList sel.ShowSelectionWindow(List, () => Grep('<args>', GrepCurDir))
