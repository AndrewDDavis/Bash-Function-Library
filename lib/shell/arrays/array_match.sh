array_match () {

    # function docs
    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Test array elements for match to a pattern

        Usage: array_match [options ...] <array-name> <pattern>

        The 'array-name' argument is the name of an existing array variable; don't pass
        the whole expanded array. If the variable pointed to by 'array-name' is a scalar
        string rather than an array, the shell will treat it as an array of length 1.

        By default, matching uses Posix ERE regular expression syntax to match an entire
        array element, rather than a substring.

        Options

        -E : pattern is Posix ERE regex
        -F : pattern is a fixed string
        -i : case-insensitive match
        -n : print the index or key of the first matching array element
        -p : print the value of the first matching array element. If both -n and -p are
             used, the output is in the form 'key:value'.
        -s : allow substring match within array elements
        -v : invert the logic: test for elements that do not match the pattern

        The return status is 0 (true) for a match, 1 (false) for no match, or > 1 if an
        error occurs.

        Examples

        arr=('one' 'bananas' 'apples' 'two words')

        # returns true:
        array_match arr bananas

        # returns false:
        array_match arr banana

        # returns true:
        array_match -s arr banana

        # returns true:
        array_match arr 'ban.*'

        # returns false:
        array_match -F arr 'ban.*'

        # returns true and prints the element index:
        array_match -n arr 'ban.*'
        # 2

        # returns true and prints the index and the matching element:
        array_match -np arr 'ban.*'
        # 2
        # bananas
        "
        docsh -TD
        return
    }

    # clean up local funcs
    trap '
        unset -f _grep_run
        trap - return
    ' RETURN

    # defaults and arg-parsing
    local re_type=E _i _n _p _x=x _v _verb=1

    local flag OPTARG OPTIND=1
    while getopts "EFinpsv" flag
    do
        case $flag in
            ( E | F )
                re_type=$flag ;;
            ( i )
                _i=i ;;
            ( n )
                _n=1 ;;
            ( p )
                _p=1 ;;
            ( s )
                unset _x ;;
            ( v )
                _v=v ;;
            ( \? )
                err_msg 2 "illegal option: '$OPTARG'"
                return ;;
        esac
    done
    shift $(( OPTIND - 1 ))


    # positional args
    [[ $# -eq 2 ]] || return 2

    # - array nameref and pattern (or string)
    local -n arrnm=$1   || return
    local ptn=$2        || return
    shift 2

    # check valid name
    [[ -v arrnm[@] ]] ||
        { err_msg 3 "not a valid name: '${!arrnm}'"; return; }

    # Both matching styles below use grep
    #
    # - I originally tried a form using Bash '[[': [[ "${arrnm[@]}" =~ $ptn ]]. This was
    #   very concise, but not totally precise: an expression combining two adjascent
    #   array values with a space between matches, even though it should not.
    #
    # Relevant grep options:
    #   -F : pattern is a fixed string
    #   -E : pattern is an ERE
    #   -q : quiet (also quits immediately on match, which helps efficiency)
    #   -x : match whole lines
    #   -z : null-terminated lines
    #   -m <n> : stop after finding <n> matches
    #   -n : prefix each output line with the 1-based line number (e.g. '53:...')
    local grep_opts+=( -q${re_type}${_x-}${_i-}${_v-} )

    # grep returns with status 0 for a match, 1 for no match
    local grep_rs=1

    _grep_run() {
        (
            grep_cmd=$( builtin type -P grep )
            [[ $_verb -gt 1 ]] && set -x
            "$grep_cmd" "${grep_opts[@]}" -e "$ptn"
        )
        grep_rs=$?
    }

    if [[ -z ${_n-}  &&  -z ${_p-} ]]
    then
        # Just return binary answer

        # use null-terminated strings
        grep_opts+=( -z )

        # - NB, adding '-n -m1' to capture the line number and use it as the index would
        #   sometimes work, but not for associative arrays, or indexed arrays with
        #   non-contiguous indexes. Also, grep keeps the null from the input, rather
        #   than removing it, so you would need to strip it or convert it to a newline
        #   if capturing output (e.g. with tr).

        _grep_run < <( printf '%s\0' "${arrnm[@]}" )

    else
        # Print matching element and/or its index (or key)
        # - use a loop to work for all arrays (associative, non-contig indexed)

        local key

        for key in "${!arrnm[@]}"
        do
            # debug
            [[ $_verb -gt 2 ]] &&
                printf >&2 ':key:%s::arrnm[key]:%s:\n' "$key" "${arrnm[$key]}"

            _grep_run <<< "${arrnm[$key]}"

            if [[ $grep_rs -eq 0 ]]
            then
                if [[ -n ${_n-}  &&  -n ${_p-} ]]
                then
                    printf '%s:%s\n' "$key" "${arrnm[$key]}"

                elif [[ -n ${_n-} ]]
                then
                    printf '%s\n' "$key"

                elif [[ -n ${_p-} ]]
                then
                    printf '%s\n' "${arrnm[$key]}"
                fi
                break
            fi
        done
    fi

    return $grep_rs
}
