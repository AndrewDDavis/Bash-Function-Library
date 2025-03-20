[[ -n $( command -v getfattr ) ]] && {

    ls-attr() {

        : "list file extended attributes, including system ones"

        [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
            { docsh -TD; return; }

        (
            set -x
            getfattr -d -m - "$@"
        )
    }

    alias ls-xattr="ls-attr"
}
