#!/usr/bin/env bash

# File Search functions using find

find-colour() {

    : "Colourize find results using ls

    Usage: find-colour [path] [search-terms]

    All arguments are passed to the 'find' command, then the results are passed through
    ls to colourize the results.

    The output isn't exactly the same as the colorization of fd and bfs, since those
    programs selectively color the dir portion of a path.
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    command find "$@" -exec ls -1pd --color '{}' \;
}

find-today() {

    : "Find items that were modified today

    Usage: find-today [path] [search-terms]

    All arguments are passed to the 'find' command, then arguments are added to limit
    the search results to files modified today.
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    command find "$@" -daystart -mtime -1
}

find-newest() {

    : "Find newest files in a directory tree

    Usage: find-newest [-n N] [path] [search-terms]

    All arguments are passed to the \`find\` command. The results are printed in a format
    that includes the modification date, and then \`sort\` and \`head\` are used to limit
    the results.

    The '-n' option may be used to limit the results to the newest N files (default 12).

    Examples

      # newest 6 files or symlinked files with extension .sh under the current directory
      find-newest -n 6 -L . -type f -name '*.sh'

      # newest 12 files modified in the last week, not including those in .git/
      find-newest -L . -name .git -prune -o \( -type f -mtime 7 \)
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # defaults and args
    local n_lines=12

    local flag OPTARG OPTIND=1

    while getopts ':n:' flag
    do
        case $flag in
            ( n )
                n_lines=$OPTARG

                # ensure positive int
                [ "$n_lines" -gt 0 ] ||
                    return 2
                ;;
            ( '?' )
                # Unknown option
                # - preserve it for 'find'
                OPTIND=$(( OPTIND - 1 ))
                break
                ;;
            ( ':' )
                # Missing arg
                err_msg 2 "missing argument for '${OPTARG}'"
                return
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    command find "$@" -printf "%TF %TH:%TM %p\n" \
        | sort -rn \
        | head -n $n_lines
}

find-borklinks() {

    : "Print broken symlinks within a directory tree

    Usage: find-borklinks [path] [search-terms]

    All arguments are passed to the 'find' command, then arguments are added to limit
    the search results to broken symlinks.
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # Re. non-broken symlinks:
    # - this style generally works, but will follow symlinks in the tree:
    #       find -L "$@" -type l
    # - the below style doesn't follow symlinks, unless user issues -L

    command find "$@" -type l -xtype l
}
