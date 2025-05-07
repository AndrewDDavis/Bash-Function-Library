array_sort() {

    : "Sort array elements

    Usage: array_sort <array-name> [sort-options]

    The sort command is used to sort the values, using null line-termination to
    preserve special characters. Refer to the sort manpage for option details.

    Only indexed arrays are accepted, since associative arrays don't have an order.

    Examples

      abc=( 2 7 999 3 )

      # reverse-order numeric sort
      array_sort abc -nr

      declare -p abc
      # declare -a abc=([0]=\"999\" [1]=\"7\" [2]=\"3\" [3]=\"2\")
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

    # sort command with options
    local sort_cmd
    sort_cmd=( "$( builtin type -P sort )" ) \
        || return 9

    sort_cmd+=( "$@" -z )
    shift $#

    # ensure valid sort command
    "${sort_cmd[@]}" </dev/null \
        || return

    # note the array is expanded on the command line, so mapfile is happy to overwrite it
    mapfile -d '' __iarr__ \
        < <( "${sort_cmd[@]}" <( printf '%s\0' "${__iarr__[@]}" ) )
}
