array_pop() {

    : "Remove element(s) from an array and decrement the index of later values

    Usage: array_pop <array-name> <index> [index ...]

    If the indexed element does not exist, the array is left untouched.

    To remove array elements without worrying about the index, or for associative
    arrays, just use \`unset\`:

      unset iarr[1] iarr[3]
      unset aarr[foo]

    To remove gaps from the index, use array_reindex().

    Examples

      abcs=( a b c d e f )

      # remove the 1st and 3rd elements
      array_pop abcs 0 2

      declare -p abcs
      # declare -a abcs=([0]=\"b\" [1]=\"d\" [2]=\"e\" [3]=\"f\")
    "

    [[ $# -lt 2  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # nameref to array
    local -n __iarr__=$1 \
        || return
    shift

    # check valid array
    [[ -v __iarr__[@]  &&  ${__iarr__@a} == *a* ]] ||
        { err_msg 3 "not an indexed array: '${!__iarr__}'"; return; }


    # sort indices as decreasing, for efficiency
    local k idcs i j

    idcs=( $( sort -gr < <( printf '%s\n' "$@" ) ) )
    shift $#

    for k in "${idcs[@]}"
    do
        is_int $k ||
            { err_msg 4 "not an integer index: '$k'"; return; }

        [[ -v __iarr__[$k] ]] ||
            continue

        unset __iarr__[$k]

        # reindex later values
        # array_reindex -c$k "${!__iarr__}"

        # actually, retain any existing gaps
        for i in "${!__iarr__[@]}"
        do
            # ignore earlier values
            (( i < k )) && continue

            # later indices must be decremented by 1
            j=$(( i - 1 ))
            __iarr__[$j]=${__iarr__[$i]}
            unset __iarr__[$i]
        done
    done
}
