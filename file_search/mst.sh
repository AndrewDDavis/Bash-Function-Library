mst() {

    : "Search for files using mate-search-tool

    Usage: mst [options] [pattern [root-dir]]

    This function launches \`mate-search-tool\` with the '--follow' and '--hidden'
    options, to show hidden files and follow symlinks. If no root-dir is specified for
    the search, --path='.' is added to the command line.

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

    [[ $# -gt 0  && $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local a noa=0 opts=( --follow --hidden )

    # filter args for positional (non-option) args
    for a in "$@"
    do
        # m-s-t only takes arguments of the form --flag or --flag=value
        if [[ $a == -* ]]
        then
            opts+=( "$a" )

        else
            if [[ $noa -eq 0 ]]
            then
                opts+=( --regex="$a" --start )

            elif [[ $noa -eq 1 ]]
            then
                opts+=( --path="$a" )

            else
                err_msg 3 "too many positional args"
                return
            fi
            (( ++noa ))
        fi
    done

    [[ $noa -lt 2 ]] &&
        opts+=( --path='.' )

    (
        set -x
        mate-search-tool "${opts[@]}" &
    )
}
