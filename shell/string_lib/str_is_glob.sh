str_is_glob() {

    : "check whether any string passed is a wildcard pattern"

    local s rs=1

    for s in "$@"
    do
        # check for glob wildcard characters '?', '*', or '[' and ']'
        if [[ $s == *[][?*]* ]]
        then
            rs=0
            break
        fi
    done

    return $rs
}
