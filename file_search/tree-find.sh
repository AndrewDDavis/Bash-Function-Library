# list files matching glob
alias find-tree='tree-find'

tree-find() {

    : "Search for files matching pattern, display as tree

        Usage: tree-find <pattern> [opts] [--] [dir1] ...

        Default modes of this function:

          - case insensitive pattern matching
          - match dirs as well as files

        All options are passed to tree. Notable options:

        -a : include hidden files, like 'ls -A'
        -d : print only directories
        -D : print dates
        -L : max depth of tree listing (CWD = 1)
        -I <pat> : exclude files matching pattern

        Other notes:

          - pattern is similar to a glob with extglob, allowing alternatives with '|'.
          - consider using --noreport (Omits report at the end of the listing).
    "
    [[ $# -eq 0 ||  $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # NB: in this context, with -P and --matchdirs, --prune causes directories that
    #     don't match the pattern, and don't contain matching files, to be omitted from
    #     the listing. Directories with names that match the pattern are not removed,
    #     even if they are empty.

    local tree_cmd
    tree_cmd=$( builtin type -P tree ) \
        || return

    "$tree_cmd" \
        --filesfirst \
        --ignore-case \
        --matchdirs \
        --prune \
        -P "$@"
}
