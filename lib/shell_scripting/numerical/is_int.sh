# posix
is_int () {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Check for valid integer

        Usage: is_int [options] <string>

        Options

        -p : positive integers only
        -z : non-negative integers only

        Examples

        # check for valid non-neg int
        if is_int -z \"\$var\"
        then
            echo \"\$var is non-neg int\"
        else
            echo \"negatory\"
        fi
        "
        docsh -TD
        return
    }

    local p=0 z=0
    local flag OPTARG OPTIND=1

    while getopts ":pz" flag
    do
        case $flag in
            ( p )
                p=1 ;;
            ( z )
                z=1 ;;
            ( '?' )
                # could be e.g. '-123'
                OPTIND=$(( OPTIND - 1 ))
                break ;;
        esac
    done
    shift $(( OPTIND-1 ))

    local s="$1"
    shift

    # in Bash, for pos/neg int, could do:
    #[[ ${s#[-+]} == +([0123456789]) ]]

    # or, some regex in AWK...
    # anyway

    if [ "$p" -eq 1 ] || [ "$z" -eq 1 ]
    then
        # pos or non-neg only
        s=${s#[+]}
    else
        # pos/neg
        s=${s#[-+]}
    fi

    case $s in

        ( *[!0-9]* | '' )
            return 1 ;;

        ( * )
            # integer

            # check for 0
            if [ "$p" -eq 1 ] && [ "$s" -eq 0 ]
            then
                return 1
            else
                return 0
            fi
    esac
}
