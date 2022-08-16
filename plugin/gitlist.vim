vim9script

export def Init()
    syntax match Type |^.*$|
enddef

def RelPath(base_path: string, path: string): string
    var Dir = (x) => (x[-1] != '/') ? x .. '/' : x
    var child_path =  substitute(path, '^' .. Dir(base_path), '', '')
    return join(mapnew(split(child_path, '/'), (_, x) => '..'), '/')
enddef

export def List(pattern: string): list<dict<any>>
    var git_top = system('git rev-parse --show-toplevel')
    var relative_git_top = RelPath(trim(git_top), getcwd())

    echo 'git ls-files "' .. relative_git_top .. '"'
    var files = systemlist('git ls-files "' .. relative_git_top .. '"')

    return mapnew(files, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x,
                select: (() => {
                    execute 'edit' escape(x, ' %')
                })
        }))

enddef

