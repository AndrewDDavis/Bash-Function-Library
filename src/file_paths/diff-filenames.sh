diff-filenames() {

    : "Compare filenames among directories

    Usage: diff-filenames [-s] <path1> <path2> [...] [search-terms]

    The \`find\` command is used to compare filenames from the specified directory
    paths, and only unique filenames are printed. All search terms are passed to
    \`find\`.

    If the '-s' option is used, this function will explicitly report when all
    filenames are identical.

    To compare the contents of files, use \`rsync\` or \`diff\`.

    Examples

      # compare only regular files from two directories
      diff-dir_fns dir1 dir2 -type f
    "

    local _s
    [[ ${1-} == -s ]] &&
        { _s=1; shift; }

    [[ $# -lt 2  || ${1-} == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # get basenames of unique filenames
    # - %P : File's name with the search starting-point removed.
    local uniq_bns
    mapfile -t uniq_bns < \
        <(  command find "$@" -printf '%P\n' \
                | sort \
                | uniq -u )

    if [[ ${#uniq_bns[@]} -gt 0 ]]
    then
        # add a find -path arg for each file
        local i f_args=( '(' )

        for i in "${!uniq_bns[@]}"
        do
            [[ $i -gt 0 ]] &&
                f_args+=( '-o' )

            f_args+=( -path "*/${uniq_bns[i]}" )
        done

        f_args+=( ')' )

        command find "$@" "${f_args[@]}"

    elif [[ -n ${_s-} ]]
    then
        printf >&2 '%s\n' "All filenames are identical."
    fi
}
