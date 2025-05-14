# TODO:
# - test optstring
# - test sourcing instead of calling

# dependencies (implied)
# import_func docsh err_msg \
#     || return

longopts() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Handle --long-opts and --key=value command line arguments

        Usage

            longopts <var-name>
            longopts <optstring> <var-name> [\"\$@\"]

        This function aids argument parsing of long options in shell scripts and
        functions. By adding simple call to this function within a typical 'while
        getopts ...' argument parsing loop, both long and short options can be handled
        by the same case statement.

        The 'var-name' argument refers to the same flag variable as in the \`getopts\`
        command call. Pass the name, e.g. 'flag' or 'OPT', not the value.

        The string '-:' must be added to the optstring of the \`getopts\` command call.
        Retain any short option flags in the optstring, which are processed by getopts
        in the usual way.

        If the optstring argument is supplied to longopts, it will be used to check
        the option flag that was received. It checks that the optstring list includes
        the flag, and that required arguments were provided. If the positional
        arguments are supplied to longopts, or BASH_ARGV is set, they will be used
        to obtain a missing argument.

        The optstring format is a space-separated list of long option flags. Flags that
        require an argument should be annotated with a trailing colon (':'), just as
        with the getopts optstring. E.g., the optstring 'abc def: ghi' indicates that
        the --def flag requires an argument, but neither --abc nor --ghi do.

        Notes

          - Recall that getopts assigns the current option flag to the var-name
            variable, and assigns its argument to the OPTARG variable, if applicable.

          - The '-:' string causes getopts to process long options by setting the flag
            variable to '-' and putting the remainder of the flag string in OPTARG. It
            is an error if the flag variable is '-', but OPTARG is empty.

            If var-name is not '-' when longopts is called, it silently returns
            with status code 0 (true). This allows argument parsing for short options
            to proceed as usual, typically with a case statement.

          - When the command-line argument was of the form '--key=value', longopts
            sets the flag variable to 'key' and OPTARG to 'value'. For an argument like
            '--long', the flag variable becomes 'long', and OPTARG is unset.

          - The error reporting also mimics getopts, and silent error reporting is
            indicated by starting the optstring with ':', or setting OPTERR=0.

        Example

          # Allow a '--aaa' flag as a synonym for '-a', and similarly '--bbb=arg'
          # for '-b arg'.

          local flag OPTARG OPTIND=1
          while getopts 'ab:-:' flag    # <- -: added to optstring
          do
              # handle long options
              longopts flag        # <- call longopts before the case statement

              case \$flag in
                  ( a | aaa ) _a=1  ;;
                  ( b | bbb ) _b=\$OPTARG  ;;
                  ( * ) err_msg 3 \"unexpected: '\$flag', '\${OPTARG-}'\"; return  ;;
              esac
          done
        "
        docsh -TD
        return
    }

    # convert optstring to array, if provided
    # - also check for silent error reporting
    # - e.g. optstr=([0]="abc" [1]="def:" [2]="ghi")
    local optstr_arr=() _silerr

    [[ ${OPTERR-} == 0 ]] \
        && _silerr=1

    if (( $# > 1 ))
    then
        # check for silent error reporting
        [[ ${1:0:1} == ':' ]] \
            && _silerr=1

        # split on spaces, newlines, tabs
        read -ra optstr_arr -d '' < \
            <( printf '%s\0' "${1#:}" )
        shift
    fi

    # - safer variable name to avoid collision with actual variable
    local -n __sl_Flag__=$1
    shift

    [[ $__sl_Flag__ == '-' ]] \
        || return 0

    [[ -n ${OPTARG-} ]] \
        || { err_msg 4 "empty OPTARG"; return; }


    # set FLAG and OPTARG as getopts does for short options
    if [[ $OPTARG == *=* ]]
    then
        # was a --key=val argument
        # - shell subs avoid external calls to 'cut'
        __sl_Flag__=${OPTARG%%=*}
        OPTARG=${OPTARG#*=}

    else
        # was a simple --flag argument
        __sl_Flag__=$OPTARG
        unset OPTARG
    fi


    if [[ -v optstr_arr[*] ]]
    then
        # optstring provided: check for expected flags and required args
        local opt_flag matched=0

        for opt_flag in "${optstr_arr[@]}"
        do
            if [[ ${opt_flag%:} == "$__sl_Flag__" ]]
            then
                matched=1
                break
            fi
        done

        if (( matched == 0 ))
        then
            # unrecognized flag
            # - mimic getopts err reporting
            if [[ -v _silerr ]]
            then
                OPTARG=$__sl_Flag__
                __sl_Flag__='?'

            else
                printf >&2 '%s\n' "longopts: illegal option -- $__sl_Flag__"
                __sl_Flag__='?'
                unset OPTARG
            fi

        elif [[ $opt_flag == *: \
            && ! -v OPTARG ]]
        then
            # arg req'd but not defined by --key=value style arg
            if (( $# ))
            then
                # get OPTARG from command-line args
                # - this works because getopts would have advanced OPTIND
                if [[ -v $OPTIND ]]
                then
                    OPTARG=${!OPTIND}
                    (( OPTIND++ ))
                fi

            else
                # if 'shopt -s extdebug' was on when the calling script was initiated,
                # then BASH_ARGV may have the OPTARG
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
            fi

            # if OPTARG wasn't found above, mimic getopts err reporting
            if [[ ! -v OPTARG ]]
            then
                if [[ -v _silerr ]]
                then
                    OPTARG=$__sl_Flag__
                    __sl_Flag__=':'

                else
                    printf >&2 '%s\n' "longopts: option requires an argument -- $__sl_Flag__"
                    __sl_Flag__='?'
                    unset OPTARG
                fi
            fi
        fi
    fi
}
