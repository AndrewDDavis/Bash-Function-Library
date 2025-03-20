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
