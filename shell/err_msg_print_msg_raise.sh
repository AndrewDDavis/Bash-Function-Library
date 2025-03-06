# TODO:
# - incorporate the functions from ~/Sync/Code/Backup/borg_go/bin/bgo_functions.sh

err_msg() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Print simple messages to stderr and set a return status.

        Usage

          err_msg <rs> [\"message body\" ...]

        The value of 'rs' may be an integer to set a return code, 'w' for a warning, or
        'i' for info. In the case of 'w' or 'i', the return code is 0.

        The message body consists of 1 or more strings to output on stderr with
        explanatory info for the user.

        This function issues non-zero exit code if requested, but won't necessarily
        cause the calling function to return. If that is desired, these solutions work:

        - Use a return call in the calling function, e.g.:
          err_msg 2 'lorem ipsum' || return \$?

        - Set an error trap in the calling function, e.g.:
          trap 'trap-err $?
                return' ERR

        Examples:

        1) err_msg 1 \"valueError: foo should not be 0\" || return \$?
        2) err_msg w \"file missing, that's not great but OK\" || return \$?
        "
        docsh -TD
        return
    }

    # TODO:
    # - options -p for custom printf format string
    # - options -n and -m for prepend and postpend newlines
    # - see and cf. log func

    # return status (exit code)
    local rs=$1
    shift


    # define severity level
    local severity=ERROR

    case $rs in
        ( w )
            severity=WARNING
            rs=0
        ;;
        ( i )
            severity=INFO
            rs=0
        ;;
    esac

    # Use generic message body if none supplied
    [[ $# -eq 0 ]] &&
        set -- "return status was $rs"


    ### Define context of err_msg call

    local call_nm call_srcfn call_srcln

    # - calling function name (if any)
    call_nm=${FUNCNAME[1]-}

    # - caller source file (or 'main', or 'source')
    call_srcnm=$( basename "${BASH_SOURCE[1]-}" )

    # - calling line in source file (or line of interactive shell)
    # - refers to a condensed form of the calling function, as seen by 'type'
    call_srcln=${BASH_LINENO[0]-}

    # create message string(s) to report context
    local context report=()

    if [[ -z $call_nm  &&  -z $call_srcnm ]]
    then
        context="(main?, l. $call_srcln)"

    elif [[ -n $call_nm  &&  $rs -eq 0 ]]
    then
        context="${call_nm}()"

    else
        context="${call_nm}() in '$call_srcnm'"
    fi

    [[ $rs -gt 0 ]] && context="code $rs from $context"

    report=( "[$severity] ${context}" )


    ## Determine whether report will fit on one line
    local _ol=''

    if [[ $rs -eq 0 ]] &&
       [[ $# -eq 1  &&  $1 != *$'\n'* ]] &&
       [[ $( str_len "${report[0]}: $1" ) -lt $( tput cols ) ]]
    then
        _ol=1
    fi


    ## Formatting

    # Bold errors and warnings
    [[ $severity == @(ERROR|WARNING) ]] &&
        report[0]=${report[0]/#\[${severity}\]/[${_cbo-}${severity}${_crb-}]}
        # severity=${_cbo-}${severity}${_crb-}

    # Bold function, underline file
    #context=${context/$call_nm/${_cbo-}${call_nm}${_crb-}}
    # context=${context/$call_srcnm/${_cul-}$call_srcnm${_cru-}}
    report[0]=${report[0]/%${call_srcnm}\)/${_cul-}${call_srcnm}${_cru-})}


    ## Print context and message body, with standardized intentation

    if [[ -n $_ol ]]
    then
        # one-liner
        report[0]="${report[0]}: $1"

    else
        # first line
        # printf >&2 '[%s] (%s):\n' "$severity" "$context"
        report[0]="${report[0]}:"

        # body line(s) with consistent indentation
        local _filt body_str _ind='    '

        _filt="
            s/^[[:blank:]]*/$_ind/
            s/\n/\n${_ind}/g
        "

        for body_str in "$@"
        do
            report+=( "$( sed -E "$_filt" <<< "$body_str" )" )
        done

        # add whitespace above and below errors and warnings
        [[ $rs -gt 0 ]] &&
            report=( '' "${report[@]}" '' )
    fi

    printf >&2 '%s\n' "${report[@]}"
    return $rs
}

export -f err_msg

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

sh_log() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "print messages from functions.

        Usage example

        # set verbosity level to info
        _verb=6

        ${FUNCNAME[0]} -v6 "something happened"
        "
        return 0
    }

    # TODO
    # - allow logfile setting to get output at certain verbosity
    # - and allow stdout verbosity level, so some messages are printed
    echo not implemented
    return

    # __VERBOSE=6

    # declare -A LOG_LEVELS
    # # https://en.wikipedia.org/wiki/Syslog#Severity_level
    # LOG_LEVELS=( [0]="emerg"
    #              [1]="alert"
    #              [2]="crit"
    #              [3]="err"
    #              [4]="warning"
    #              [5]="notice"
    #              [6]="info"
    #              [7]="debug" )
    # function .log () {
    #   local LEVEL=${1}
    #   shift
    #   if [ ${__VERBOSE} -ge ${LEVEL} ]; then
    #     echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
    #   fi
    # }
}
