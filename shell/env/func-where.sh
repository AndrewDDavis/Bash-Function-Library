func-where() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Show file path containing a function definition

        Usage: func-where <func-name> ...

        This function temporarily enables the extdebug option, then runs
        \`declare -F\` with the supplied arguments.
        "
        docsh -TD
        return
    }

    local func_nm s src_fn src_ln regex_ptn

    # define regex separately to avoid shell quoting issues
    regex_ptn='^([^ ]+) ([0-9]+) (.+)$'

    (
        shopt -s extdebug

        for func_nm in "$@"
        do
            [[ $( builtin type -at "$func_nm" ) == *function* ]] ||
                { err_msg w "function not found: '$func_nm'"; continue; }

            s=$( declare -F "$func_nm" )

            # E.g.:
            # - for the_func() defined in 'a func.sh', declare -F would output:
            #   'the_func 1 a func.sh'
            # - then, [[ $sss =~ ^([^ ]+)\ ([0-9]+)\ (.+)$ ]] would produce:
            #   BASH_REMATCH=([0]="the_func 1 a func.sh" [1]="the_func" [2]="1" [3]="a func.sh")

            [[ $s =~ $regex_ptn ]]
            src_fn=${BASH_REMATCH[3]}
            src_ln=${BASH_REMATCH[2]}

            # src_fn=${s#* * }
            # src_ln=${s#* }
            # src_ln=${src_ln% ${src_fn}}

            # grep-style output
            [[ $# -gt 1 ]] &&
                printf '%s' "${func_nm}: "

            printf '%s\n' "ln. $src_ln in '$src_fn'"
        done
    )
}
