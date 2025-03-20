array_strrepl() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Replace array element matching string with one or more new elements

        Usage: array_strrepl <array-name> <string> [elem1 [elem2 ...]]

        The first array element that exactly matches the string is replaced by elem1,
        then any further elements are added to follow. If no new elements are provided,
        the matching element is deleted. Indices following the replaced element
        are adjusted as explained by array_irepl().
        "
        docsh -TD
        return
    }

    # array name and pattern, then remaining args are new elements
    local -n __earr__=$1    || return
    local s=$2          || return
    shift 2

    # check valid array
    [[ -v __earr__[@]  &&  ${__earr__@a} == *[aA]* ]] ||
        { err_msg 3 "not an array: '${!__earr__}'"; return; }


    # rely on other array functions where possible
    local k rs
    k=$( array_match -nF -- "${!__earr__}" "$s" ) || {
        # allow status = 1 for no match
        rs=$?
        [[ $rs == 1 ]] && return 1
        err_msg $rs "error in array_match"
        return
    }


    if [[ ${__earr__@a} == *A* ]]
    then
        # associative array
        if [[ $# -eq 0 ]]
        then
            unset __earr__["$k"]

        elif [[ $# -eq 1 ]]
        then
            __earr__["$k"]=$1

        else
            err_msg 5 "associative arrays can only take one element"
            return
        fi
    else
        # pass the original array name, to save a layer of abstraction
        array_irepl "${!__earr__}" "$k" "$@"
    fi
}
