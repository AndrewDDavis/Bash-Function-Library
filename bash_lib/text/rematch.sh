# TODO
# - timing: putting docstrings at the top of this function took the execution time from
#   ~170 us to ~290 us, amazingly; got to get docsh working with strings that are not
#   in the function definition. Even putting the no-op and string argument inside the
#   'if' statement for $# eq 0 adds ~ 35 ms to the execution time.
# - the return trap, which unsets functions and resets itself, accounts for ~ 25 us of
#   the runtime, whereas populating the array of subfunctions accounts for another 10 us.
# - reading the function definitions themselves accounts for ~ 20 us
# - the docsh test on $# | -h accounts for only a few us. Same with the getopts call;
#   the whole _parse_args function takes only ~ 20 us.
# - trying to juggle the function definitions so that rematch -q can skip reading the
#   unneeded functions did save a bit of time, ~3 us per function skipped, but probably
#   isn't worth it, due to how strange the code looks. Pre-declaring functions using
#   declare -f func actually added a few us to the execution time.

: """Test for pattern match using Bash regex comparison

    Usage

        rematch 'pattern' 'string'
        rematch 'pattern' <<< test-string
        rematch 'pattern' < /path/to/text/file

    Match a string or text from stdin against a regex pattern. The pattern uses
    POSIX extended regular expression syntax, and the effect is similar to grep -E,
    but works more quickly since no external program is started. In some ways,
    using this function is also more convenient, since the results are placed
    directly into variables, without having to worry about handling printed output.

    When the regex comparison is tested, Bash places matching strings and sub-
    expressions in the BASH_REMATCH array (refer to the bash manpage for details).
    This function defines the REMATCHES array, which works similarly. REMATCHES
    will contain the BASH_REMATCH arrays of all matches. E.g., for a pattern with 2
    sub-expressions that matches 4 times, REMATCHES would have 12 elements. When no
    matches occur, the array is declared but empty.

    The REMATCH_N variable is also defined, containing a count of the number of
    matches. The number of elements of REMATCHES is equal to REMATCH_N times the
    number of pattern sub-expressions.

    Options

      -l
      : Match within lines, rather than as a free-flowing string. In this context,
        '-p' prints lines rather than matching strings, and '^' and '$' in the
        pattern match the start and end of lines, rather than the start and end of
        the whole string. The REMATCHES variable still contains matching strings
        and sub-expressions, but an additional variable, REMATCH_LINES, is defined,
        which contains matching lines.

      -p
      : Print matched string segments, or lines if using '-l'.

      -q
      : Only return true or false; don't test for multiple matches, don't print
        anything, and don't set the REMATCHES or REMATCH_LINES arrays.

    Notes

      - To make rematch behave like a call to 'grep -E', call it as 'rematch -lp' to
        operate line-by-line and print matching lines. When rematch is called without
        options, it has similar functionality to 'grep -Eoc'.

      - Timing: when matching a pattern against a string, 'rematch -q' took ~0.10 ms. A
        non-matching 'rematch -p' was similar, but a matching call took ~0.15 ms. By
        comparison, GNU grep took ~1.4 ms, and ugrep took ~3.8 ms to perform the same
        match. Notably, for simple comparisons, directly running [[ ... =~ ... ]] took
        only ~0.008 ms.

      - A null-matching pattern, such as '' or 'a*', always matches. However, it
        produces only 1 match, consisting of the null string. This differs from
        grep, which reprints the entire input. Null-matching sub-expressions work
        similarly. E.g., '(a*)(b*)' produces three null elements in BASH_REMATCH
        and REMATCHES, and REMATCH_N=1, regardless of the input text.

      - Returns true (status code 0) on a match, 1 for no match, or > 1 on an error.
"""

rematch() {

    # uncomment when docsh can handle strings in the source file:
    # [[ $# -eq 0  || $1 == @(-h|--help) ]] \
    #     && { docsh -TD; return; }

    # cleanup routine and func definitions
    trap '
        unset -f _parse_args _match_lines \
            _match_string _match_printer
        trap - return
    ' RETURN

    _parse_args() {

        # option parsing
        local flag OPTARG OPTIND=1
        while getopts ':lpq' flag
        do
            case $flag in
                ( l ) _l=1 ;;
                ( p ) _p=1 ;;
                ( q ) _q=1 ;;
                ( : )  err_msg 2 "missing argument for $OPTARG"; return ;;
                ( \? ) err_msg 3 "unknown option: '$OPTARG'"; return ;;
            esac
        done
        shift $(( OPTIND-1 ))

        # positional arg is pattern
        (( $# > 0 )) \
            || { err_msg 3 "missing pattern argument"; return; }

        (( $# < 3 )) \
            || { err_msg 4 "too many arguments: ${*@Q}"; return; }

        ptn=$1

        if (( $# > 1 ))
        then
            txt=$2
        else
            txt=$( < /dev/stdin )
        fi
    }

    _match_lines() {

        # line-by-line matching
        # local ln_match

        # NB, <<< appends a newline to txt
        while IFS= read -r
        do
            # test for one or more matches within the line
            _match_string "$REPLY" \
                && REMATCH_LINES+=( "$REPLY" )

            # while [[ $REPLY =~ $ptn ]]
            # do
            #     (( ++REMATCH_N ))
            #     REMATCHES+=( "${BASH_REMATCH[@]}" )

            #     [[ ! -v ln_match ]] && {
            #         REMATCH_LINES+=( "$REPLY" )
            #         ln_match=1
            #     }

            #     REPLY=${REPLY#*"${BASH_REMATCH[0]}"}
            # done

            # NB, local variables stay local, even when unset
            # unset ln_match

        done <<< "$txt"

        # return true/false
        (( REMATCH_N ))
    }

    _match_string() {

        # test for one or more matches within the string
        local str=$1

        while [[ $str =~ $ptn ]]
        do
            (( ++REMATCH_N ))
            REMATCHES+=( "${BASH_REMATCH[@]}" )

            str=${str#*"${BASH_REMATCH[0]}"}
        done

        # return true/false
        # - if string and $1 are no longer the same, a match occurred
        #   (allows calling this func from _match_lines)
        [[ $str != "$1" ]]
    }

    _match_printer() {

        if [[ -v _p  && ! -v _q  && REMATCH_N -gt 0 ]]
        then
            # print matching segments or lines
            if [[ -v _l ]]
            then
                printf '%s\n' "${REMATCH_LINES[@]}"
            else
                local i n step
                n=${#REMATCHES[*]}
                step=$(( n / REMATCH_N )) \
                    || return

                # NB, building an array and calling printf once took ~7 us *longer*
                for (( i=0; i<n; i=i+step ))
                do
                    printf '%s\n' "${REMATCHES[i]}"
                done
            fi
        fi
    }

    # variable defaults
    unset REMATCHES REMATCH_N REMATCH_LINES || return
    declare -ag REMATCHES=()
    declare -ig REMATCH_N=0
    local _l _p _q
    local txt ptn

    _parse_args "$@" || return
    shift $#

    if [[ -v _q ]]
    then
        # simple binary test
        [[ $txt =~ $ptn ]] \
            && REMATCH_N=1

    elif [[ '' =~ $ptn ]]
    then
        # null-matching pattern
        # - e.g. (a*)(b*): BASH_REMATCH=([0]="" [1]="" [2]="")
        REMATCHES=( "${BASH_REMATCH[@]}" )
        REMATCH_N=1

    elif [[ -v _l ]]
    then
        declare -ag REMATCH_LINES=()
        _match_lines "$txt" || return

    else
        _match_string "$txt" || return
    fi

    _match_printer || return

    # test for any matches and return true/false
    (( REMATCH_N ))
}
