_split_optarg() {

    [[ $# -eq 0 ]] && {

        : "Split --key=value command line arguments

        Usage: _split_optarg <flag var-name>

        This function is meant to be used within \`while getopts ...\` argument parsing
        loops. It splits '--key=value' arguments into a more convenient form that may be
        handled by the same case statement as the short options. The argument should be
        a string representing the same variable name as was given to getopts, not the
        value of the variable.

        This function expects '-:' to appear in the getopts string, so that getopts will
        set the flag variable to '-' for a long option. If the flag variable is not '-'
        when the function is called, it takes no action. For an argument of the form
        '--long' this function will set the flag variable to 'long', and OPTARG will be
        unset. For an argument like '--key=value', the flag variable will be set to
        'key', and OPTARG will be set to 'value'.

        As an alternative to this function, consider using 'getopts_long'.

        Example: Allow --aaa as a synonym for -a, and similarly for -b arg and
                 --bbb=arg:
        ...
        local flag OPTARG OPTIND=1
        while getopts 'ab:c-:' flag
        do
            # handle long options
            _split_optarg flag

            case \$flag in
                ( a | aaa )
                    _aaa=True
                ;;
                ( b | bbb )
                    _bbb=\${OPTARG:?}  # display error msg and exit if OPTARG is Null or Unset
                ;;
            ...
        "
        docsh -TD
        return
    }

    [[ $# -eq 1 ]] ||
        { err_msg 2 "args error: $@"; return; }

    local -n _f=$1
    shift

    if [[ $_f == '-' ]]
    then
        [[ -n ${OPTARG-} ]] ||
            { err_msg 2 "empty OPTARG"; return; }

        # recreate FLAG and OPTARG from 'key=val' or 'long'
        if [[ $OPTARG == *=* ]]
        then
            _f=$( cut -d= -f1 <<< "$OPTARG" )
            OPTARG=$( cut -d= -f2 <<< "$OPTARG" )
        else
            _f=$OPTARG
            unset OPTARG
        fi
    fi
}
