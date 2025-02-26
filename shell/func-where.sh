func-where() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Show file path containing a function definition

        Usage: ${FUNCNAME[0]} <func-name> ...

        This function temporarily enables the extdebug option, then runs
        \`declare -F\` with the supplied arguments.
        "
        docsh -TD
        [[ $# -gt 0 ]]
        return
    }

    local func s src_fn src_ln

    (
        shopt -s extdebug

        for func in "$@"
        do
            command grep -q function < <( type -at "$func" ) ||
                { err_msg w "function not found: '$func'"; continue; }

            s=$( declare -F "$func" )

            # declare -F output for the_func() defined in 'a func.sh':
            # 'the_func 1 a func.sh'
            src_fn=${s#* * }
            src_ln=${s#* }
            src_ln=${src_ln% ${src_fn}}

            # grep-style output
            [[ $# -gt 1 ]] && printf '%s' "${func}: "
            printf '%s\n' "ln. $src_ln in '$src_fn'"
        done
    )
}
