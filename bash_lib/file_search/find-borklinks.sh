find-borklinks() {

    : """Print broken symlinks within a directory tree

    Usage: find-borklinks [path] [search-terms]

    All arguments are passed to the 'find' command, then arguments are added to limit
    the search results to broken symlinks.
    """

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # Re. non-broken symlinks:
    # - this style generally works, but will follow symlinks in the tree:
    #       find -L "$@" -type l
    # - the below style doesn't follow symlinks, unless user issues -L

    command find "$@" -type l -xtype l
}
