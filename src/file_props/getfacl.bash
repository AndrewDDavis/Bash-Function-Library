[[ -n $( command -v getfacl ) ]] && {

    ls-acl() {

        : "list file ACLs"

        [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
            { docsh -TD; return; }

        (
            set -x
            getfacl -pt "$@"
        )
    }

    alias ls-perms="ls-acl"
}
