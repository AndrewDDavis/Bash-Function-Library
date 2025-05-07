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
    local -n __earr__=$1 \
        || return
    shift

    [[ $# -eq 0 ]] ||
        return 2


    # ensure we got a non-empty array
    # [[ -v __earr__[*]  && ${#__earr__[*]} -gt 0 ]] ||
    [[ -v __earr__[*]  && ${__earr__@a} == *[aA]* ]] ||
        { err_msg 3 "need a non-empty array, got '${!__earr__}'"; return; }

    trap 'unset -f _elem_isint' RETURN

    _elem_isint() {

        is_int "${__earr__[$1]}" ||
            { err_msg 4 "${!__earr__}[$1] not an int: '${__earr__[$1]}'"; return; }
    }


    # loop over array to find the max
    local i _max idcs

    # indices of referenced array
    idcs=( "${!__earr__[@]}" )

    i=${idcs[0]}
    _elem_isint "$i" \
        || return

    _max=${__earr__[$i]}

    for i in "${idcs[@]:1}"
    do
        _elem_isint "$i" \
            || return

        (( ${__earr__[$i]} <= _max )) \
            || _max=${__earr__[$i]}
    done

    printf '%s\n' "$_max"
}
