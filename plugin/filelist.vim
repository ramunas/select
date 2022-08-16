vim9script

export def Init()
    syntax match Type |^.*$|
enddef

def Partition(list: list<any>, Pred: func(any): bool): list<list<any>>
    var a = []
    var b = []
    for x in list
        if pred(x)
            add(a, x)
        else
            add(b, x)
        endif
    endfor
    return [a,b]
enddef

export def List(pattern: string): list<dict<any>>
    var all_files = glob('*' .. pattern .. '*', true, true, true)

    var [directories, files] = Partition(all_files, isdirectory)

    return mapnew(files, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x,
                select: (() => {
                    execute 'edit' escape(x, ' %')
                })
        }))

enddef

