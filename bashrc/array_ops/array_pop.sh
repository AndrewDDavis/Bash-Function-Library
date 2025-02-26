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

      # indexed array: remove element #4
      array_pop iarr 4
    "

    [[ $# -lt 2  ||  $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # nameref to array
    local -n iarr=$1 || return
    shift

    [[ $# -gt 0 ]] || return 2

    # check valid array
    [[ -v iarr[@]  &&  ${iarr@a} == *a* ]] ||
        { err_msg 3 "not an indexed array: '${!iarr}'"; return; }


    # sort indices as decreasing, for efficiency
    local k idcs i j

    idcs=( $( sort -gr < <( printf '%s\n' "$@" ) ) )
    shift $#

    for k in "${idcs[@]}"
    do
        is_int $k ||
            { err_msg 4 "not an integer index: '$k'"; return; }

        [[ -v iarr[$k] ]] ||
            continue

        unset iarr[$k]

        # reindex later values
        # array_reindex -c$k "${!iarr}"

        # actually, retain any existing gaps
        for i in "${!iarr[@]}"
        do
            # ignore earlier values
            (( i < k )) && continue

            # later indices must be decremented by 1
            j=$(( i - 1 ))
            iarr[$j]=${iarr[$i]}
            unset iarr[$i]
        done
    done
}
