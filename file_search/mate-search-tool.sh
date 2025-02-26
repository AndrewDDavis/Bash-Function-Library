mst() {

    : "launch mate-search-tool from the current directory

    Usage: mst [options] [pattern]

    The \`mst\` function launches \`mate-search-tool\` with the following options, whether
    or not a pattern was provided: '--path=.', '--follow', and '--hidden'.

    If a pattern is provided, it is interpreted as a regex pattern matching a substring
    of the filename, and the search is started immediately. The regex syntax seems a bit
    quirky: it appears to be ERE, as meta-charcters like '+', '(', and '|' do not
    require a leading '\'. However, to match literal '.', use '[.]' rather than '\.'.

    To start a search using a glob pattern or substring of the filename, use
    --named='pattern'. If the pattern contains no globbing characters, it is interpreted
    as a substring (i.e. the glob '*pattern*').

    For documentation of all options, refer to the \`mate-search-tool\` manpage. For
    more complete documentation of the application, refer to 'Search for Files' in the
    Gnome help browser application.
    "

    [[ $# -gt 0  &&  $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local args=( --path=. --follow --hidden )

    # parse pattern
    [[ $# -gt 0  &&  ${@: -1} != -* ]] && {
        args+=( --regex="${@: -1}" --start )
        set -- "${@:1:$(($#-1))}"
    }

    mate-search-tool "${args[@]}" "$@" &
}
