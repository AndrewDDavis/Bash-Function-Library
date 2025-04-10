seqi() {

    : "Print a sequence of integers

        Usage: seqi [first [increment]] last

        This function prints integers from first to last, in steps of increment. If
        first is omitted, it defaults to 1. If increment is omitted, it defaults to 1
        if last is greater than first, otherwise to -1. The increment may not be 0. The
        sequence ends when adding the increment would make a number greater than last,
        or less than last then the increment is negative.

        Although seqi works similarly to GNU seq, there are differences:

          - This function only prints integer values, and does not handle floating
            point values at all.

          - If last is less than first, and increment is omitted, the increment is -1.

        Options

        -s <string>
        : separate printed numbers using this string (default: newline)

        -w
        : equalize width of printed numbers by padding with leading zeroes
    "

    # defaults and options
    local _s='\n' _w

    local flag n OPTARG OPTIND=1
    while getopts ':s:wh' flag
    do
        case $flag in
            ( s ) _s=$OPTARG ;;
            ( w ) _w=1 ;;
            ( h ) docsh -TD; return ;;
            ( \? )
                [[ $OPTARG == [0-9] ]] && {
                    # consider 'first' args of -2 or -16, which look like option flags
                    n=$(( OPTIND-1 ))
                    [[ ${!n} == -[0-9] ]] \
                        && (( OPTIND-- ))
                    break
                }
                err_msg 3 "unknown option: '-$OPTARG'"
                return
            ;;
            ( : ) err_msg 4 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # positional args: [first [increment]] last
    local frst incr last
    case $# in
        ( 0 ) docsh -TD; return ;;
        ( 1 ) frst=1;  last=$1 ;;
        ( 2 ) frst=$1; last=$2 ;;
        ( 3 ) frst=$1; incr=$2; last=$3 ;;
        ( * ) err_msg 5 "too many arguments: '$*'"; return ;;
    esac
    shift $#

    # ensure incr has a value
    if [[ -z ${incr-} ]]
    then
        incr=1
        (( frst > last )) \
            && incr=-1

    elif (( incr == 0 ))
    then
        err_msg 5 "increment may not be 0"
        return
    fi

    # longest string could be first or last, e.g. -2 vs 3
    # - 'seq -w -2 3' prints -2 -1 00 01 02 03
    local slen=${#frst}
    (( ${#last} > ${#frst} )) \
        && slen=${#last}

    # set width format string
    # e.g. printf '%03d\n' 3
    local fmt=''
    [[ -v _w ]] \
        && fmt=0${slen}

    fmt="%${fmt}d"

    # define the comparison
    local comp
    if (( incr > 0 ))
    then
        comp='i<=last'
    else
        comp='i>=last'
    fi

    # create string of formatted integers
    local i ostr=''
    for (( i=frst; "$comp"; i=i+incr ))
    do
        ostr+=$( printf "$fmt" "$i" )
        ostr+=$_s
    done

    # strip the last separator and print the string with a newline
    if [[ -n $ostr ]]
    then
        ostr=${ostr%"$_s"}
        printf '%s\n' "$ostr"
    fi
}
