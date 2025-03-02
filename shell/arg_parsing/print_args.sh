_print_args() {

    [[ $# -eq 1  &&  $1 == -h ]] && {

        : "Print options and positional parameters in a compact but readable format"
        docsh -TD
        return
    }

    # match array index to pos'n params
    local args=( "${@:0}" )
    unset args[0]

    if [[ $# -gt 0 ]]
    then
        local _filt='
            s/declare -a args=(/args: /
            s/)$//
        '

        builtin declare -p args |
            command sed "$_filt"

    else
        builtin printf >&2 '%s\n' "args: # (empty)"
    fi
}
