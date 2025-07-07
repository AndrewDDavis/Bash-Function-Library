: """Copy file permissions and ACLs

    Usage: cp-acl <file 1> <file 2>

    Runs getfacl file1 | setfacl --set-file=- file2.
"""

cp-acl() {

    [[ $# -ne 2  || $1 == @(-h|--help) ]] \
        && { docsh -TD; return; }

    local gf_cmd sf_cmd
    gf_cmd=$( builtin type -P getfacl ) \
        || return 9
    sf_cmd=$( builtin type -P setfacl ) \
        || return 10

    # use ps to capture return statuses adn return with max
    local ps=()

    "$gf_cmd" "$1" | "$sf_cmd" --set-file=- "$2"
    ps=( "$PIPESTATUS[@]" )

    local -i v rs=0
    for v in "${ps[@]}"
    do
        (( v > rs )) && rs=$v
    done

    return $rs
}
