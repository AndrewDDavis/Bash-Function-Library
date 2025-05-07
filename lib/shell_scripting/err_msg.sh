# TODO:
# - incorporate the functions from ~/Sync/Code/Backup/borg_go/bin/bgo_functions.sh
# - see and cf. log func

err_msg() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Print messages to stderr and set a return status

        Usage: err_msg <rs> [\"message body\" ...]

        The value of 'rs' should be one of:

          - An integer to set the return status code for err_msg. Values > 0 will print
            an error message, 0 triggers a warning.
          - 'w' to print a warning (return status is 0).
          - 'i' to print an info message (return status is 0).
          - 'd' to print a debug message (return status is 0).

        The message body consists of 1 or more strings to output on STDERR with
        explanatory info for the user.

        This function issues a non-zero return status code if requested, but that won't
        necessarily cause the calling function to return. To do that, you can:

          - Use 'return' in the calling function (this preserves the value), e.g.:

            err_msg 2 'lorem ipsum'; return

          - Set an error trap in the calling function, e.g.:

            trap '
                trap-err $?
                return
            ' ERR

        Examples

            err_msg 1 \"valueError: foo should not be 0\"; return

            err_msg w \"file missing, that's not great but OK\"
        "
        docsh -TD
        return
    }

    # return status (exit code)
    local rs=$1
    shift

    # define severity level
    local severity=ERROR

    case $rs in
        ( w | 0 )
            severity=WARNING
            rs=0
        ;;
        ( i )
            severity=INFO
            rs=0
        ;;
        ( d )
            severity=DEBUG
            rs=0
        ;;
    esac

    # Use generic message if none was supplied
    [[ $# -eq 0 ]] &&
        set -- "return status was $rs"


    ### Define context of err_msg call
    local -A caller
    caller=( [name]= [srcnm]= [srcln]= )

    # - calling function names (if any)
    [[ -v 'FUNCNAME[1]' ]] && {

        caller[name]=${FUNCNAME[1]}'()'

        [[ -v 'FUNCNAME[2]' ]] && {

            local i
            for (( i=2; i<${#FUNCNAME[*]}; i++ ))
            do
                caller[name]+=", ${FUNCNAME[i]}()"
            done
        }
    }

    # - caller source file (or 'main', or 'source', maybe 'environment')
    caller[srcnm]=$( basename "${BASH_SOURCE[1]-}" )

    # - calling line in source file (or line of interactive shell)
    # - refers to a condensed form of the calling function, as seen by 'type'
    caller[srcln]=${BASH_LINENO[0]-}

    # create message string(s) to report context
    local context report=()

    if [[ -z ${caller[name]}  && -z ${caller[srcnm]} ]]
    then
        context="(unknown source, l. ${caller[srcln]})"

    elif [[ -z ${caller[name]}  && -n ${caller[srcnm]} ]]
    then
        # e.g. from a sourced file, not a function
        context="${caller[srcnm]}, l. ${caller[srcln]}'"

    elif [[ $rs -eq 0 ]]
    then
        # e.g. warning from a function
        context=${caller[name]}

    else
        context="${caller[name]} in '${caller[srcnm]}'"
    fi

    [[ $rs -gt 0 ]] &&
        context="code $rs from $context"

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
        report[0]=${report[0]/#"[${severity}]"/"[${_cbo-}${severity}${_crb-}]"}

    # Underline file (don't bold function, was too much)
    report[0]=${report[0]/%"${caller[srcnm]}'"/"${_cul-}${caller[srcnm]}${_cru-}'"}


    ## Print context and message body, with standardized indentation

    if [[ -n $_ol ]]
    then
        # one-liner
        report[0]="${report[0]}: $1"

    else
        # first line
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
