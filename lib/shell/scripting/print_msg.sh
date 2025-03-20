print_msg() {

    docstr="Print log-style messages to stderr.

    Usage: ${FUNCNAME[0]} [msg-type] <message>

    Examples

        ${FUNCNAME[0]} ERROR \"the script had a problem\"

        ${FUNCNAME[0]} \"info message\"
    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "$docstr"
        return 0
    }

    local msg_type=INFO

    [[ $1 == @(DEBUG|INFO|WARNING|ERROR) ]] && {
        msg_type=$1
        shift
    }

    printf >&2 "%s %s %s\n" "$(date)" "${exc_fn--} [$msg_type]" "$*"
}
