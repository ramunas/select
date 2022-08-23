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
    if !exists('b:git_ls_path')
        b:git_ls_path = ''
        b:git_ls_result = []
    endif
    if path == b:git_ls_path
        return b:git_ls_result
    endif
    b:git_ls_result = systemlist('git ls-files "' .. path .. '"')
    b:git_ls_path = path
    return b:git_ls_result
enddef

export def List(pattern: string): list<dict<any>>
    var git_top = system('git rev-parse --show-toplevel')
    if v:shell_error
        echoerr git_top
        return []
    endif
    var relative_git_top = trim(git_top)
    # var relative_git_top = RelPath(trim(git_top), getcwd())

    var files = GitLsFiles(relative_git_top)

    var reg_pattern = glob2regpat('*' .. pattern .. '*')
    files = filter(copy(files), (_, b) => (b =~ reg_pattern))

    return mapnew(files, (_, x): dict<any> => (
        {
                view: () =>
                    '  ' .. x,
                select: (() => {
                    execute 'edit' escape(x, ' %')
                })
        }))

enddef

