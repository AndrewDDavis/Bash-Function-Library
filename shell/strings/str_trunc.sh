str_trunc()
(
    [[ $# -lt 2  ||  $1 == @(-h|--help) ]] &&
    {
        docsh -TD "Shorten a string, substituting '...'.

        Usage

          ${FUNCNAME[0]} [opts] <n> <str>

            n : maximum character length allowed
          str : string to shorten (e.g. path, directory name)

        Options

          -m : truncate in the middle (default)
          -s : truncate at the start
          -e : truncate at the end

        Example

          ${FUNCNAME[0]} 12 the_path_to_shorten
        "
        return 0
    }

	local sloc=m

    local OPT OPTARG OPTIND=1

    while getopts "mse" OPT
    do
        case $OPT in
            ( m ) sloc=m ;;
            ( s ) sloc=s ;;
            ( e ) sloc=e ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    local n=$1 pstr=$2

    if (( ${#pstr} <= $n ))
    then
        printf '%s\n' "$pstr"

    else
        # int char lengths trimmed from start and end
        local a b

        # trim $pstr to $n chars
        case $sloc in
            ( m )
                a=$(( (n - 3)/2 ))

                # handle odd/even case
                if (( (n % 2) == 0 ))
                then
                    b=$(( -1*(a + 1) ))
                else
                    b=$(( -1*a ))
                fi
            ;;
            ( s )
                a=0
                b=$(( -1*(n - 3) ))
            ;;
            ( e )
                a=$(( n - 3 ))
                b=${#pstr}
            ;;
        esac

        printf '%s\n' "${pstr::$a}...${pstr:($b)}"
    fi
)
