# TODO:
# - test optstring

split_longopt() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Split --key=value command line arguments

        Usage

            split_longopt <variable-name>
            split_longopt <optstring> <variable-name> [\"\$@\"]

        This function is meant to be used within 'while getopts ...' argument parsing
        loops. It splits '--key=value' arguments into a more convenient form, so that
        both long and short options may be handled by the same case statement.

        The variable-name argument is the name of a 'flag' variable, not its value.
        Typically, this would be the same variable name as the one supplied to the
        getopts command call (e.g. 'flag' or 'OPT').

        If the optstring argument is used, split_longopt will check that long option
        flags are in the list. It will also check that required arguments were
        provided. The optstring format is a space-separated list of words, which
        represent the long option flags. If a word includes a trailing colon (':'),
        that flag requires an argument. E.g., in the optstring 'abc def: ghi', the
        '--def' flag would require an argument. If the positional arguments are
        provided, and a required argument is missing, split_longopt will attempt to
        fetch it from the CLI arguments.

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
            split_longopt flag

            case \$flag in
                ( a | aaa )
                    _a=1
                ;;
                ( b | bbb )
                    _b=\${OPTARG:?}
                    # ^^^ displays error msg and return if OPTARG is Null or Unset
                ;;
                ( * )
                    err_msg 3 \"unexpected: '\$flag', '\${OPTARG-}'\"
                    return
                ;;
            esac
        done
        "
        docsh -TD
        return
    }

    # parse optstring as an array, if provided
    # - e.g. optstr=([0]="abc" [1]="def:" [2]="ghi")
    local optstr_arr _silerr

    (( $# > 1 )) && {

        # silent error reporting
        [[ ${1:0:1} != ':' ]] ||
            _silerr=1

        # split on spaces
        read -ra optstr_arr <<< "${1#:}"
        shift
    }

    # safer variable name avoids collision btw nameref and actual variable
    local -n __flagvar_ref__=$1
    shift

    [[ $__flagvar_ref__ == '-' ]] ||
        return 0

    [[ -n ${OPTARG-} ]] ||
        { err_msg 4 "empty OPTARG"; return; }

    # recreate FLAG and OPTARG from 'key=val' or 'long'
    if [[ $OPTARG == *=* ]]
    then
        # - avoid external calls to 'cut' by using shell string subst
        __flagvar_ref__=${OPTARG%%=*}
        OPTARG=${OPTARG#*=}

    else
        __flagvar_ref__=$OPTARG
        unset OPTARG
    fi

    if [[ -v optstr_arr[*] ]]
    then
        # optstring provided: check for expected flags and required args
        local os_flag matched=0

        for os_flag in "${optstr_arr[@]}"
        do
            if [[ ${os_flag%:} == "$__flagvar_ref__" ]]
            then
                matched=1
                break
            fi
        done

        if (( matched == 0 ))
        then
            # unexpected flag
            # - mimic getopts err reporting
            if [[ -v _silerr ]]
            then
                OPTARG=$__flagvar_ref__
                __flagvar_ref__='?'

            else
                printf >&2 '%s\n' "split_longopt: illegal option -- $__flagvar_ref__"
                __flagvar_ref__='?'
                unset OPTARG
            fi

        else
            if [[   ${os_flag:(-1)} == ':' \
                    && ! -v OPTARG ]]
            then
                # arg req'd and not yet defined
                if [[ -v $OPTIND ]]
                then
                    # get opt-arg from CLI
                    # - only works if user provided "$@" argument
                    OPTARG=${!OPTIND}
                    (( OPTIND++ ))

                else
                    # - otherwise, 'shopt -s extdebug' would have needed to be on in
                    #   when the calling script was initiated; then BASH_ARGV would
                    #   have what we need here

                    if [[ -v BASH_ARGV[*] ]]
                    then
                        local -i a b n i
                        a=${BASH_ARGC[0]}    # e.g. 2 args for this func
                        b=${BASH_ARGC[1]}    # e.g. 4 args for the calling func
                        n=${#BASH_ARGV[@]}   # e.g. 6

                        # for the above e.g., arg 3 of the calling func is available at BASH_ARGV[2]
                        # 0 1 2 3 4 5

                        if (( b >= OPTIND ))
                        then
                            i=$(( n - 1 - a - (b - OPTIND) ))
                            OPTARG=${BASH_ARGV[i]}
                            (( OPTIND++ ))
                        fi
                    fi

                    if [[ ! -v OPTARG ]]
                    then
                        # printf >&2 '%s\n' "split_longopt: not enough BASH_ARGV for argument to '$__flagvar_ref__'"

                        if [[ -v _silerr ]]
                        then
                            OPTARG=$__flagvar_ref__
                            __flagvar_ref__=':'

                        else
                            printf >&2 '%s\n' "split_longopt: option requires an argument -- $__flagvar_ref__"
                            __flagvar_ref__='?'
                            unset OPTARG
                        fi
                    fi
                fi
            fi
        fi
    fi
}
