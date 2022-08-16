vim9script

export def Init()
    syntax match Type |^.*$|
    syntax match Type |^.*\.|me=e-1
    syntax match Normal |\..*$|
    syntax match Directory |^.*/$|
    syntax match Directory |\[.*\]|
    # syntax match Special |\[.*\]|
    b:last_dir = getcwd()
enddef

def Partition(list: list<any>, Pred: func(any): bool): list<list<any>>
    var a = []
    var b = []
    for x in list
        if Pred(x)
            add(a, x)
        else
            add(b, x)
        endif
    endfor
    return [a, b]
enddef

export def List(pattern: string): list<dict<any>>
    var glob_pattern = (pattern == '') ? '*' : '*' .. pattern .. '*'
    var re_pattern = glob2regpat(glob_pattern)
    var all_files = glob(glob_pattern, true, true, true)

    var [directories, files] = Partition(all_files, (f) => isdirectory(f))

    sort(files)
    sort(directories)

    var result = []

    extend(result, mapnew(files, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x,
                select: (() => {
                    execute 'edit' escape(x, ' %')
                })
        })))

    extend(result, mapnew(directories, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x .. '/',
                select: (() => {
                    execute ':' w:selection_window 'wincmd w'
                    b:selection_keep_open = true
                    b:last_dir = getcwd()
                    execute 'cd' escape(x, ' %')
                })
        })))

    var special = [
        {
                name: '..',
                view: () => '..',
                select: () => {
                    execute ':' w:selection_window 'wincmd w'
                    b:selection_keep_open = true
                    b:last_dir = getcwd()
                    cd ..
                }
        },
        {
                name: '--',
                view: () => '-- [' .. b:last_dir .. ']',
                select: () => {
                    execute ':' w:selection_window 'wincmd w'
                    b:selection_keep_open = true
                    var dir = b:last_dir
                    b:last_dir = getcwd()
                    execute 'cd' dir
                }
        }
        ]

    filter(special, (_, x) => x['name'] =~ re_pattern)

    extend(result, special)

    return result
enddef

