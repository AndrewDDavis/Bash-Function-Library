func-where() {

    : "Show file path of a function definition

        Usage: func-where [-s] <func-name> ...

        This function prints the file path and line number for the definition of a
        function. It temporarily enables the extdebug option, then runs 'declare -F'
        to get the information.

        If the -s option is passed, the function is re-imported by sourcing the
        relevant file path instead of printing it.
    "

    # defaults and options
    local _s

    local flag OPTARG OPTIND=1
    while getopts ':sh' flag
    do
        case $flag in
            ( s ) _s=1 ;;
            ( h ) docsh -TD; return ;;
            ( \? ) err_msg 3 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 4 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # clean-up trap
    trap '
        unset -f _func_not_found
        trap - return
    ' RETURN

    _func_not_found() {

        # not a function; check for alias
        if dec_out=$( alias "$func_nm" 2>/dev/null )
        then
            err_msg 5 "not a function, but found alias: ${dec_out#*=}"
        else
            err_msg 6 "function not found: '$func_nm'"
        fi
    }

    # record state of extdebug, and enable it
    local _ed_state
    if shopt extdebug >/dev/null
    then
        _ed_state=1
    fi

    shopt -s extdebug


    # gather func defn info
    local regex_ptn func_nm dec_out src_fn src_ln src_cmd

    # Define regex separately to avoid shell quoting issues
    # - Pattern matches function name, line number, and source file path
    # - E.g. for the_func() defined in 'a func.sh', declare -F would output:
    #   'the_func 1 a func.sh'
    # - Then, [[ $sss =~ ^([^ ]+)\ ([0-9]+)\ (.+)$ ]] would produce:
    #   BASH_REMATCH=([0]="the_func 1 a func.sh" [1]="the_func" [2]="1" [3]="a func.sh")
    regex_ptn='^([^ ]+) ([0-9]+) (.+)$'

    for func_nm in "$@"
    do
        dec_out=$( declare -F "$func_nm" ) \
            || { _func_not_found; continue; }

        [[ $dec_out =~ $regex_ptn ]]
        src_fn=${BASH_REMATCH[3]}
        src_ln=${BASH_REMATCH[2]}

        # source if requested
        if [[ -v _s ]]
        then
            src_cmd=( builtin source "$src_fn" )
            printf >&2 '%s\n' "${PS4}${src_cmd[*]}"
            "${src_cmd[@]}"

        else
            # grep-style output
            [[ $# -gt 1 ]] &&
                printf '%s' "${func_nm}: "

            printf '%s\n' "ln. $src_ln in '$src_fn'"
        fi
    done

    # reset extdebug
    if [[ -v _ed_state ]]
    then
        shopt -s extdebug
    fi
}
