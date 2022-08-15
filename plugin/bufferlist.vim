vim9script

export def BufferListInit()
    syntax match LineNr |\<[0-9]\+\>|
    syntax match Type |^.\{-} |
enddef

export def BufferListSelection(pattern: string): list<dict<any>>
    var buf_list = getbufinfo({buflisted: 1})
    var Bname = (b) => fnamemodify(bufname(b['bufnr']), ':t')
    var Relpath = (n) => fnamemodify(n, ':.')

    var reg_pattern = glob2regpat('*' .. pattern .. '*')
    buf_list = filter(buf_list, (_, b) => (Bname(b) =~ reg_pattern))

    var max_width = max(mapnew(buf_list, (_, b) => len(Bname(b))))

    # float the alterante buffer to the top
    var alt = b:alternate_buffer
    for i in range(len(buf_list))
        if buf_list[i]['bufnr'] == alt
            var tmp = buf_list[0]
            buf_list[0] = buf_list[i]
            buf_list[i] = tmp
            break
        endif
    endfor

    return mapnew(buf_list, (_, x): dict<any> => (
        {
                view: () =>
                    printf('%-' .. max_width .. 's %3d %s', Bname(x), x['bufnr'], Relpath(x['name'])),
                select: (() => {
                    execute 'buffer' x['bufnr']
                })
        }))
enddef

