# deps
import_func array_sort argmax \
    || return

array_pop() {

    : "Remove array element(s) and decrement later indices

    Usage: array_pop <array-name> [index ...]

    If no index is provided, 0 is used. If an indicated array element does not exist,
    a warning is printed. Providing pre-sorted indices speeds up execution.

    To remove array elements without modifying the index, or for associative arrays,
    use the unset built-in:

      unset iarr[1] iarr[3]
      unset aarr[foo]

    To remove all gaps from an array's index, use array_reindex.

    Examples

      abcs=( a b c d e f )

      # remove the 1st and 3rd elements
      array_pop abcs 0 2

      declare -p abcs
      # declare -a abcs=([0]=\"b\" [1]=\"d\" [2]=\"e\" [3]=\"f\")
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # nameref to array
    local -n __iarr__=$1 \
        || return
    shift

    # check valid array
    [[ -v __iarr__[*]  && ${__iarr__@a} == *a* ]] ||
        { err_msg 3 "not an indexed array: '${!__iarr__}'"; return; }

    # last array index
    local m
    m=$( argmax "${!__iarr__[@]}" )

    # default index to remove is 0
    (( $# == 0 )) \
        && set -- 0

    # check args are valid indices
    local i idcs=()
    for (( i=1; i<=$#; i++ ))
    do
        is_int ${!i} ||
            { err_msg 4 "not a valid index: '${!i}'"; return; }

        if [[ -v __iarr__[${!i}] ]]
        then
            idcs+=( "${!i}" )
        else
            err_msg w "${!__iarr__} has no element at ${!i}"
        fi
    done
    shift $#

    local n=${#idcs[*]}

    if (( n == 0 ))
    then
        return 0

    elif (( n == 1 ))
    then
        # Unset idx and decrement later values
        local j=${idcs[0]}
        unset '__iarr__[j]'

        for (( i=j+1; i<=m; i++ ))
        do
            if [[ -v __iarr__[i] ]]
            then
                __iarr__[i-1]=${__iarr__[i]}
                unset '__iarr__[i]'
            fi
        done
    else
        # Sort the indices, so we can step through the array only once
        # - NB, for small n, calling sort takes more than half the execution time!
        #   With n=1, skipping the sort takes the time from ~15 ms to ~7ms.
        # - Providing sorted indices speeds up the execution back to ~ 7 ms.
        # So it's worth check whether the indices are already sorted.
        local srtd=1 j=${idcs[0]}
        for i in "${idcs[@]:1}"
        do
            (( i > j )) \
                || { srtd=0; break; }
            j=$i
        done

        (( srtd == 1 )) \
            || array_sort idcs -n

        # Unset idcs and decrement later values as we go
        # - k tracks index of the idcs array, and the number of elements that
        #   have been removed so far
        # - j tracks the index of the next element to be removed
        local j=${idcs[0]} k=1
        unset '__iarr__[j]'
        j=${idcs[1]}

        for (( i=(idcs[0]+1); i<=m; i++ ))
        do
            if (( i == j ))
            then
                unset '__iarr__[i]'
                (( ++k ))
                if [[ -v idcs[k] ]]
                then
                    j=${idcs[k]}
                else
                    j=0
                fi

            elif [[ -v __iarr__[i] ]]
            then
                # decrement index of later elements
                __iarr__[i-k]=${__iarr__[i]}
                unset '__iarr__[i]'
            fi
        done
    fi
}
