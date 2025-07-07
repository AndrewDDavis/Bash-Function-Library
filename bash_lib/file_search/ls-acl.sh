# alias that may be more memorable
alias ls-perms="ls-acl"

: """List file permissions and ACLs

    Usage: ls-acl [-r] <file-path> ...

    Uses 'getfacl -t' for tabular output of file permissions and defaults, but also
    prints a line for the flags (e.g. g=s) using the regular getfacl output.
"""

ls-acl() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local gf_cmd
    gf_cmd=$( builtin type -P getfacl ) \
        || return 9

    # flags line is not printed with -t
    local flags
    flags=$( "$gf_cmd" "$@" | grep '^# flags:' )

    # insert flags line into table
    local table
    mapfile -t table < <( "$gf_cmd" -t "$@" )

    wait $! || return

    printf '%s\n' "${table[0]}" ${flags:+"$flags"} "${table[@]:1}"
}
