vim9script

def Grep(grep: string)
    var grep_res = systemlist('grep -n "' .. grep .. '" *')
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
    var res = filter(copy(b:grep_list), (_, x) => x[0] =~ pat)

    var col_size = max(mapnew(res, (_, x) => len(x[0])))

    return mapnew(res, (_, x): dict<any> => (
        {
                view: () =>
                    printf('%-' .. col_size .. 's %3s %s', x[0], x[1], x[2]),
                select: (() => {
                    execute 'edit' x[0]
                })
        }))
enddef

import "./select2.vim" as sel
command! ShowGrepList sel.ShowSelectionWindow(List, () => Grep('mapnew'))
