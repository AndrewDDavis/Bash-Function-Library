array_max() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Print maximum value from array

        Usage: array_max <array name>

        Return status is 0 for success, 2 for more than 1 arg, 3 if the name is not a
        non-empty array, and 4 if an array element is not an integer.
        "
        docsh -TD
        return
    }

    # nameref to array
    local -n earr=$1 || return
    shift 1

    [[ $# -eq 0 ]] || return 2

    # ensure we got a non-empty array
    [[ -v earr[@]  &&  ${earr@a} == *[aA]* ]] ||
        { err_msg 3 "need a non-empty array, got '${!earr}: $( declare -p ${!earr} )'"; return; }

    trap 'unset -f _chk' RETURN

    _chk() {

        is_int ${earr[$1]} ||
            { err_msg 4 "${!earr}[$1] not an int: '${earr[$1]}'"; return; }
    }

    # loop over the array to find the max
    local i idcs _max

    idcs=( ${!earr[@]} )

    i=${idcs[0]}
    _chk $i || return
    _max=${earr[$i]}

    for i in ${idcs[@]:1}
    do
        _chk $i || return
        [[ ${earr[$i]} -le $_max ]] || _max=${earr[$i]}
    done

    printf '%s\n' "$_max"
}
