# TODO:
# - allow passing the optstring, so that the function can check whether a value was
#   passed, and potentially grap the next arg

_split_optarg() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Split --key=value command line arguments

        Usage: _split_optarg <variable-name>

        This function is meant to be used within 'while getopts ...' argument parsing
        loops. It splits '--key=value' arguments into a more convenient form, so that
        both long and short options may be handled by the same case statement.

        The function argument should be the name of a 'flag' variable, not its value.
        Typically, this would be the same variable name as the one specified in the
        getopts command call (e.g. 'flag' or 'OPT').

        This function expects that '-:' appeared in the \`getopts\` optstring, so that
        getopts parsed a long option by setting the flag variable to '-' and putting
        the remainder of the flag string in OPTARG. If the value of the flag variable
        is not '-', the function silently returns with status code 0 (true). An error
        condition occurs if the flag variable is '-' but OPTARG is empty.

        When OPTARG resulted from an argument of the form '--key=value', this function
        sets the flag variable to 'key' and OPTARG to 'value'. For an argument like
        '--long' the flag variable becomes 'long', and OPTARG is unset.

        As an alternative to this function, consider using 'getopts_long'.

        Example

        # Allow a '--aaa' flag as a synonym for '-a', and similarly '--bbb=arg'
        # for '-b arg'.

        local flag OPTARG OPTIND=1
        while getopts 'ab:-:' flag
        do
            # handle long options
            _split_optarg flag

            case \$flag in
                ( a | aaa )
                    _aaa=True
                ;;
                ( b | bbb )
                    _bbb=\${OPTARG:?}
                    # ^^^ displays error msg and return if OPTARG is Null or Unset
                ;;
                ( * )
                    err_msg 3 \"unexpeced flag: '\$flag'\"
                    return
                ;;
        done
        "
        docsh -TD
        return
    }

    [[ $# -eq 1 ]] ||
        { err_msg 2 "exactly 1 arg expected, got: '$*'"; return; }

    # variable name avoids collision btw nameref and actual variable
    local -n __flagvar_ref__=$1
    shift

    [[ $__flagvar_ref__ == '-' ]] ||
        return 0

    [[ -n ${OPTARG-} ]] ||
        { err_msg 4 "empty OPTARG"; return; }

    # recreate FLAG and OPTARG from 'key=val' or 'long'
    if [[ $OPTARG == *=* ]]
    then
        __flagvar_ref__=${OPTARG%%=*}
        OPTARG=${OPTARG#*=}

        # ^^^ avoids the external calls to 'cut'
        # __flagvar_ref__=$( cut -d= -f1 <<< "$OPTARG" )
        # OPTARG=$( cut -d= -f2 <<< "$OPTARG" )
    else
        __flagvar_ref__=$OPTARG
        unset OPTARG
    fi
}
