tar-list() {

    : "List files in a tar archive.

    Usage: tar-list [opts] <archive-file>

    Notes

      - Tar starts listing right away, but must read the header for each file block
        before it can finish the list. The file blocks occur sequentially throughout
        the file, so this entails reading the whole file before the listing
        operation completes. As long as the file is seekable (force with -n), this
        may not be too bad.

      - If a large archive is commonly listed, better archive formats include [zip](https://askubuntu.com/a/1036234/52041)
        and possibly [dar](https://github.com/Edrusb/DAR).
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local targs=( '-tv' )

    # archive filename must be last arg
    targs+=( "${@:1:$#-1}" -f "${@:(-1)}" )

    command tar "${targs[@]}"
}
