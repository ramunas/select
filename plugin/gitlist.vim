vim9script

export def Init()
    syntax match Type |^.*$|
enddef

def RelPath(base_path: string, path: string): string
    var Dir = (x) => (x[-1] != '/') ? x .. '/' : x
    var child_path =  substitute(Dir(path), '^' .. Dir(base_path), '', '')
    child_path = substitute(child_path, '/$', '', '')
    var rel_path = join(mapnew(split(child_path, '/'), (_, x) => '..'), '/')
    return (rel_path == '') ? '.' : rel_path
enddef



def GitLsFiles(path: string): list<string>
    if path == b:git_ls_path
        return b:git_ls_result
    endif
    var files = systemlist('git ls-files "' .. path .. '"')
    b:git_ls_path = path
    b:git_ls_result = files
    return files
enddef

export def List(pattern: string): list<dict<any>>
    var git_top = system('git rev-parse --show-toplevel')
    var relative_git_top = RelPath(trim(git_top), getcwd())

    b:git_ls_path = ''
    b:git_ls_result = []

    var files = GitLsFiles(relative_git_top)

    var reg_pattern = glob2regpat('*' .. pattern .. '*')
    files = filter(files, (_, b) => (b =~ reg_pattern))

    return mapnew(files, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x,
                select: (() => {
                    execute 'edit' escape(x, ' %')
                })
        }))

enddef

