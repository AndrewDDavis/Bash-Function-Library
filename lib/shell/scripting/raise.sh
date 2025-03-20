raise() {

    docstr="Print error message and exit with code.

    Usage: ${FUNCNAME[0]} <code> <message>

    Examples

      ${FUNCNAME[0]} 2 \"valueError: foo should not be 0\"

      ${FUNCNAME[0]} w \"file missing, that's not great but OK\"
    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "$docstr"
        return 0
    }

    local rs=${1:?"${FUNCNAME[0]} requires exit code"}
    local msg_body=${2:?"${FUNCNAME[0]} requires message"}

    local msg_type=ERROR
    [[ $rs == w ]] && {
        msg_type=WARNING
        rs=0
    }

    print_msg "$msg_type" "$msg_body"
    exit $rs
}
