array_irepl() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Replace array element at index with one or more new elements

        Usage: array_irepl <array-name> <index> [elem1 [elem2 ...]]

        Adding more than one new element to a non-sparse, indexed array causes the
        indices after the replaced element to be increased, as necessary. If no
        replacement elements are provided, the indexed element is deleted, and the
        following indices are decremented, as in array_pop().

        This function is not necessary for associative arrays: there is no implied order
        of the keys, so just replace or add new elements using their keys.

        Examples

          # replace element #4 with two others
          array_irepl iarr 4 abc def
        "
        docsh -TD
        return
    }

    # array name and index, then remaining args are new elements
    local -n iarr=$1    || return
    local k=$2          || return
    shift 2

    # check valid array and index
    [[ -v iarr[@]  &&  ${iarr@a} == *a* ]] ||
        { err_msg 3 "not an indexed array: '${!iarr}'"; return; }

    is_int $k ||
        { err_msg 4 "not an integer index: '$k'"; return; }


    if [[ $# -eq 0 ]]
    then
        # no new elements: delete the element and adjust the index
        array_pop "${!iarr}" $k

    elif [[ $# -eq 1 ]]
    then
        # one new element: trivial replacement
        iarr[$k]=$1

    else
        # add elements to the array, taking into account sparseness

        # NB, for a non-sparse array, adding array elements will cause the last index to
        # increase by 1 less than the number of new elements. But a sparse array with
        # enough 'open' indices after the replaced one may not see an increase in the
        # last index.

        # to account for this, use hole-counting strategy:
        # - each new element needs a "hole" to go into, otherwise new indices will be
        #   added to the end of the array
        # - k can *always* be counted as a hole, since it's replaced regardless
        # - count holes after k (i.e. gaps in the index)
        # - calc num-holes to ignore: there may be an excess in sparse arrays
        # - track the delta btw old and new index, starting from the end

        # ign_holes=( holes - $# ), or 0 if < 0
        # delta=( $# - ( holes - ign_holes ) )

        # non-sparse: replace k=3 with 3 elements
        # - holes=1, ign_holes=0, delta=2
        # 0 1 2 3 4 5 6
        # 0 1 2 3 4 5 6 7 8

        # somewhat sparse: replace k=3 with 3 elements
        # - holes=2, ign_holes=0, delta=1
        # 1 2 3 4   6
        # 1 2 3 4 5 6 7

        # plenty sparse: replace k=6 with 4 elements
        # - holes=5, ign_holes=1, delta=0
        # 1 2 3     6   8 9       12 13 14   16
        # 1 2 3     6 7 8 9 10 11 12 13 14   16

        # missing k: replace k=3 with 2 elements
        # - holes=2, ign_holes=0, delta=0
        # 1     4 5   7
        # 1   3 4 5 6 7

        # k > i_last: replace k=3 with 2 elements
        # - holes=1, ign_holes=0, delta=1
        # - this skips the decrementing loop altogether, since (i_last < k) fails
        # 1 2
        # 1 2 3 4

        local i j=$k holes=1 i_last ign_holes=0 delta

        for i in "${!iarr[@]}"
        do
            # skip lower idcs, incl k
            [[ $i -le $k ]] && continue

            # incr holes if there is a gap in the index
            (( holes += ( i - j - 1 ) ))

            # store present index
            j=$i
        done
        i_last=$i

        (( holes > $# )) &&
            ign_holes=$(( holes - $# ))

        # delta btw old and new idcs: req. holes - used holes
        delta=$(( $# - ( holes - ign_holes ) ))

        # step through possible indices, in reverse order to avoid overwriting
        for (( i=i_last; i > k; i-- ))
        do
            # delta can increase at gaps
            [[ ! -v iarr[$i] ]] && {

                if [[ $ign_holes -gt 0 ]]
                then
                    (( ign_holes-- ))
                else
                    (( ++delta ))
                fi
                continue
            }

            j=$(( i + delta ))
            iarr[$j]=${iarr[$i]}
        done

        # then, write new elements to sequential indices from k
        for (( i=1; i <= $#; i++ ))
        do
            j=$(( k + i - 1 ))
            iarr[$j]=${!i}
        done
    fi
}
