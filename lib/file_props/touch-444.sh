touch-444() {

    : "Make a file world-readable after creation with touch

        Usage: touch-444 [-f] [tch-opt ...] <file-name ...>

        Options

          -f : force action, even if the file exists

        All other options and arguments are passed to touch.
    "

    local tch_cmd
    tch_cmd=( "$( builtin type -P touch )" ) \
        || return 9

    # option parsing
    local _f

    local flag OPTARG OPTIND=1
    while getopts ':fh' flag
    do
        case $flag in
            ( f ) _f=1 ;;
            ( h ) docsh -TD; return ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))



        elif [[ $1 != --*  && $1 == -*@(d|r|t) ]]
        then
            # touch options that take an arg

            tch_opts+=( "$1" "$2" )
            shift 2

        else
            tch_opts+=( "$1" )
            shift
        fi
    done


    # main loop
    local fn

    for fn in "$@"
    do
        [[ -e "$fn"  && -n ${_f-} ]] ||
            { err_msg 6 "file exists: $fn"; return; }

        (
            set -x
            touch "${tch_opts[@]}" "$fn" \
                && chmod o+r "$fn"
        )
    done
}
