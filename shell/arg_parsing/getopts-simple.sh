getopts-simple() {

    : "Demonstrate and test simple getopts functionality

        - Silent error reporting is enabled.

        - NB, with default error reporting, getopts prints error messages but still
          returns with status 0, so the loop merrily carries on. Another important
          difference when using default error reporting is that OPT becomes '?', not ':',
          for a missing argument.
    "

    printf '%s\n\n' "args: ${*@Q}"
    local n=1 i=1

    local OPT OPTARG OPTIND=1

    while getopts ':n:' OPT
    do
        printf '%s\n' "getopts iter $i:"
        declare -p OPT OPTARG OPTIND 2>/dev/null

        case $OPT in
            ( n )
                n=$OPTARG

                # ensure positive int
                [ "$n" -gt 0 ] || return 2
                ;;
            ( '?' )
                # Unknown option
                # - for a wrapper function, preserve it and break
                OPTIND=$(( OPTIND - 1 ))
                break
                # - otherwise, perhaps error message
                echo >&2 "Invalid option: ${OPTARG@Q}"
                return 1
                ;;
            ( ':' )
                # Missing arg
                echo >&2 "Missing argument for ${OPTARG@Q}"
                return 2
                ;;
        esac

        (( i++ ))
        printf '\n'
    done
    shift $(( OPTIND - 1 ))

    printf '%s\n' "n: ${n@Q}"
    echo "args: ${*@Q}"
}
