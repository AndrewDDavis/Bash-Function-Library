# TODO:
# - incorporate the functions from ~/Sync/Code/Backup/borg_go/bin/bgo_functions.sh
#
# - see and cf. log func
#
# - consider adding the date, maybe when an option is given:
#   printf >&2 "%s %s %s\n" "$(date)" "${exc_fn--} [$msg_type]" "$*"
#
# - allow verbosity level setting, so only some messages are printed
#   e.g., setting an env var in a function:
#   __VERBOSE=6
#
#   function .log () {
#     local LEVEL=${1}
#     shift
#     if [ ${__VERBOSE} -ge ${LEVEL} ]; then
#       echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
#     fi
#   }
#
#   # https://en.wikipedia.org/wiki/Syslog#Severity_level
#   declare -A LOG_LEVELS
#   LOG_LEVELS=( [0]="emerg"
#                [1]="alert"
#                [2]="crit"
#                [3]="err"
#                [4]="warning"
#                [5]="notice"
#                [6]="info"
#                [7]="debug" )


# dependencies
import_func is_int \
    || return

# suggestions
import_func basename 2>/dev/null \
    || true

err_msg() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Print log-style messages to stderr

        Usage: err_msg <rs> [\"message body\" ...]

        The value of 'rs' should be one of:

          - An integer, which sets the return status code of the err_msg call. Values
            > 0 will print an error message, 0 triggers a warning.
          - 'w' to print a warning (return status is 0).
          - 'i' to print an info message (return status is 0).
          - 'd' to print a debug message (return status is 0).

        The message body consists of 1 or more strings with diagnostic info to print
        on STDERR. If multiple strings are provided, they will each be printed on a
        separate line.

        Before the message body is printed, err_msg prints the message type and some
        context information, such as the function chain that led to the err_msg call.
        Formatting is applied to the output if STDERR is printing to an interactive
        shell.

        Examples

            err_msg 1 \"valueError: foo should not be 0\"; return

            err_msg w \"file missing, that's not great but OK\"

        Use in Shell Functions

        For error messages, err_msg issues a non-zero return status code. However, that
        won't necessarily cause the calling function to return. To do that, you can:

          - Use 'return' in the calling function (this preserves the value), e.g.:

            err_msg 2 'lorem ipsum'; return

          - Set an error trap in the calling function, e.g. using the trap-err function:

            trap '
                trap-err $?
                return
            ' ERR
        "
        docsh -TD
        return
    }

    # Return status (exit code) and severity level
    {
        local severity=ERROR
        local -i rs

        case $1 in
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
            ( * )
                is_int "$1" \
                    && rs=$1 \
                    || { printf >&2 '%s\n' "unknown rs: '$rs'"; return; }
            ;;
        esac
        shift
    }

    # Remaining args define message body
    {
        local body_lines
        if [[ $# -eq 0 ]]
        then
            # Use generic message if none was supplied
            body_lines=( "return status was $rs" )

        else
            # Split multi-line messages into array of lines
            mapfile -t body_lines < \
                    <( printf '%s\n' "$@" )
            shift $#
        fi
    }

    ## Define context of err_msg call
    {
        local -A caller=( [name]='' [srcnm]='' [srcln]='' )
        local context report=()

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

        # - caller source file (can also be 'main', 'source', or 'environment')
        caller[srcnm]=$( basename "${BASH_SOURCE[1]-}" )

        # - calling line in source file (or line of interactive shell)
        # - refers to a condensed form of the calling function, as seen by 'type'
        caller[srcln]=${BASH_LINENO[0]-}

        # create message string(s) to report context
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

        [[ $rs -gt 0 ]] \
            && context="code $rs from $context"
    }
    report=( "[$severity] ${context}:" )

    ## For low-severity messages, try to fit on one line
    {
        local _ol_report
        if  [[ $rs -eq 0
            && ${#body_lines[*]} -eq 1 ]]
        then
            _ol_report="${report[0]}  ${body_lines[*]}"

            [[ ${#_ol_report} -lt $( tput cols ) ]] \
                || unset _ol_report
        fi
    }

    ## Format context strings
    if [[ -t 2 ]]
    then
        # Define ANSI strings for text styles
        # - Not using _cbo from 'csi_strvars -d' function, as it has prompt ignore
        #   chars in it too (like \001), which messes up 'less' display
        local _bld=$'\e[1m' _rsb=$'\e[22m' \
            _dim=$'\e[2m' _rsd=$'\e[22m' \
            _ita=$'\e[3m' _rsi=$'\e[23m' \
            _uln=$'\e[4m' _rsu=$'\e[24m' \
            _rst=$'\e[0m'

        # Bold errors and warnings
        [[ $severity == @(ERROR|WARNING) ]] \
            && report[0]=${report[0]/#"[${severity}]"/"[${_bld}${severity}${_rsb}]"}

        # Underline file, if present (don't bold function, was too much)
        report[0]=${report[0]/%"${caller[srcnm]}'"/"${_uln}${caller[srcnm]}${_rsu}'"}
    fi


    ## Print formatted context, then message body with standardized indentation
    if [[ -v _ol_report ]]
    then
        # one-liner, like _ol_report with formatting
        report[0]+="  ${body_lines[*]}"

    else
        # body line(s) with consistent indentation
        local ln _ind='    '
        for ln in "${body_lines[@]}"
        do
            [[ $ln =~ ^([[:blank:]]*)(.*)$ ]]
            report+=( "${_ind}${BASH_REMATCH[2]}" )
        done

        # add blank line above and below errors
        [[ $rs -gt 0 ]] \
            && report=( '' "${report[@]}" '' )
    fi

    printf >&2 '%s\n' "${report[@]}"
    return $rs
}
