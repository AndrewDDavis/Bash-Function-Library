match-sh() {

    : "Test for pattern match using Bash regex comparison

        Usage

            match-sh 'pattern' 'string'
            match-sh 'pattern' <<< test-string

        This matches the string or text from STDIN against a regex pattern in a similar
        way to grep -Eq. However, this works more quickly than grep or awk, since no
        external program is started. The pattern uses POSIX extended regular expression
        syntax, and the BASH_REMATCH array is defined (refer to man bash).

        Options

          -l : match line-by-line, and store matches in BASH_REMATCHES array
          -p : print first matching line (implies -l)
          -a : when used with -p or -l, match against every line

        Returns 0 (true) for a match, or 1 for no match.
    "

    # defaults and option parsing
    local _a _p _l

    local flag OPTARG OPTIND=1
    while getopts ':aplh' flag
    do
        case $flag in
            ( a ) _a=1 ;;
            ( p ) _p=1; _l=1 ;;
            ( l ) _l=1 ;;
            ( h ) docsh -TD; return ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # positional arg is pattern
    (( $# > 0 )) ||
        { err_msg 3 "missing pattern argument"; return; }

    (( $# < 3 )) ||
        { err_msg 4 "too many arguments: ${*@Q}"; return; }

    local txt ptn=$1
    shift

    if (( $# > 0 ))
    then
        txt=$1
        shift
    else
        txt=$( < /dev/stdin )
    fi


    # test for matches
    local _yn=1
    BASH_REMATCH=()

    if [[ ! -v _l ]]
    then
        # simple binary test
        unset BASH_REMATCHES

        [[ $txt =~ $ptn ]] &&
            _yn=0

    else
        # line-by-line matching
        BASH_REMATCHES=()

        while IFS= read -r
        do
            if [[ $REPLY =~ $ptn ]]
            then
                _yn=0
                BASH_REMATCHES+=( "${BASH_REMATCH[@]}" )

                # print
                [[ -v _p ]] &&
                    printf '%s\n' "$REPLY"

                # all
                [[ -v _a ]] ||
                    break
            fi

        done <<< "$txt"
    fi

    return "$_yn"
}
