# tree lists files, accepting an optional pattern

# notable options:
# -a : print all files, including dot-files
# -s : print sizes
# -h : human-readable sizes
# -D : print dates
# -p : print permissions
# -F : print file-type indicator (/, =, *, ...)
alias tree-ash="tree -ash"

# list files matching glob
alias find-tree='tree-find'

tree-find() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Search for files matching pattern, display as tree

            Usage: $FUNCNAME <pattern> [opts] [--] [dir1] ...

            Default modes of this func:
            - case insensitive
            - match dirs as well as files

            Options are passed to tree. Notable options:

            -a       : include hidden files, like ls -A
            -I <pat> : exclude files matching pattern

            Other notes:

            - pattern is similar to a glob with extglob, allowing alternatives with '|'
            - consider using --noreport (Omits report at the end of the listing.)
            "
        return 0
    }

    # NB: in this context, with -P and --matchdirs, --prune causes directories that
    #     don't match the pattern, and don't contain matching files, to be omitted from
    #     the listing. Directories with names that match the pattern are not removed,
    #     even if they are empty.

    tree --ignore-case --matchdirs --prune -FP "$@"
}
