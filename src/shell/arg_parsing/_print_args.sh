_print_args() {

    [[ ${1-} == @(-h|--help) ]] && {

        : "Print arguments provided to the function.

        Usage: _print_args ...

        This function prints its options and positional parameters in a compact but
        readable format. It is intended for troubleshooting shell scripts during
        development.
        "

        docsh -TD
        return
    }

    # match array index to pos'n params
    # shellcheck disable=SC2034
    local args=( "${@:0}" )
    unset 'args[0]'

    if [[ $# -gt 0 ]]
    then
        # filter the output of declare -p for readability
        local decp_filt='
            s/declare -a args=(/args: /
            s/)$//
        '

        builtin declare -p args |
            command sed "$decp_filt"

    else
        builtin printf >&2 '%s\n' "# (empty args list)"
    fi
}
