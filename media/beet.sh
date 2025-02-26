[[ -n $(command -v beet) ]] && {

    # Convert and Import audio
    # - e.g. beet import [--flat] [--group-albums] dir

	eval "$(beet completion 2>/dev/null)"
}

beet-rename() {
    : "rename files on disk, and update the path in the beets library

    Usage: beet-rename <oldpath> <newpath>

    beet will ask for confirmation first.
    "

    [[ $# -lt 2 || $1 == -h ]] &&
        { docsh -TD; return; }

    local beet_cmd
    beet_cmd=$( type -P beet ) \
        || return

    /bin/mv -v "$1" "$2" \
        || return

    "$beet_cmd" modify -M "path:$1" "path=$2"
}
