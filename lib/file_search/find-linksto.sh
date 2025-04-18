# deps
import_func physpath array_from_find \
    || return

find-linksto() {

    : "Print symlinks pointing to a directory or file

    Usage: find-linksto <pattern> <search-root>

    The second argument is used as the search-root for a find commmand that matches
    symlinks within the tree.

    The first argument is used as a regex pattern (POSIX ERE) to match paths using
    Bash's regular expression matching tool.

    Examples

      # find links to, or into, the Config-Sync project directory
      find-linksto -F '/Config-Sync' ~/

      # find all links within the user's .local directory
      find-linksto . ~/.local
    "

    [[ $# -ne 2  || $1 == @(-h|--help) ]] \
        && { docsh -TD; return; }

    local pth_root ptn
    ptn=$1
    pth_root=$2
    shift $#

    # more conventional: readlink (Linux-only) and grep
    # command find "$pth_root" -type l -printf '%p -> ' -exec readlink -f {} \; \
    #     | command grep -E "$ptn"

    # TODO:
    # - Find out why the below is so slow compared to the conventional method. It's not
    #   because of == vs =~, that makes very little difference.
    #
    #   The below is cross-platform, relies on shell only, but about double the execution
    #   time(!), even just by putting the readlink and grep commands in for physpath
    #   and [[ ... =~ ... ]].
    #
    #   What's more, using the above pipe is 1/4 the time of the code below.

    local fnd_out=()
    array_from_find fnd_out "$pth_root" -type l \
        || return

    [[ ${#fnd_out[*]} -gt 0 ]] \
        || { printf >&2 '%s\n' 'No matches.'; return; }

    local fn pp
    for fn in "${fnd_out[@]}"
    do
        pp=$( physpath "$fn" )

        if [[ $pp =~ $ptn ]]
        then
            printf '%s -> %s\n' "$fn" "$pp"
        fi
    done
}
