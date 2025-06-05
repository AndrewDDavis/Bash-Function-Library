# alias that may be more memorable
alias ls-perms="ls-acl"

ls-acl() {

    : """List file ACLs

        Runs 'getfacl -pt', with supplied CLI arguments.
    """

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local gf_cmd
    gf_cmd=( "$( builtin type -P getfacl )" ) \
        || return 9

    gf_cmd+=( -pt )

    (
        set -x
        "${gf_cmd[@]}" "$@"
    )
}
