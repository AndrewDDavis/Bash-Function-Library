#!/bin/bash

# Bash variables and so-on
#
# - Can use caller like:
#   read -r ln fn < <( caller )
#   echo "${FUNCNAME[0]} was called at ln. $ln of $fn"
#
#   Using 'caller 0' should give more info, but I don't understand its output.
#
# - Shell functions and scripts executed with '.' or 'source' are considered to be
#   subroutines.
#
# - Line numbers: LINENO is the line that's executing right now,
#   whereas BASH_LINENO[0] is the line that called the current function
#
# - Source files and $0: BASH_SOURCE is an empty array for an interactive shell,
#   but is non-empty for any file executing, whether by `bash ./file` or `. ./file`.
#   In an executed file, $0 == BASH_SOURCE[0], but in a sourced file, $0 is the
#   shell command name, like '-bash' for a login shell.
#
# - Functions: When executing a function, its name is added to the FUNCNAME array,
#   and the file containing the function definition is added to the BASH_SOURCE
#   array. If the function is defined in an interactive shell, BASH_SOURCE[0]="main".
#   If the function is executed in an interactive shell, FUNCNAME[1] and
#   BASH_SOURCE[1] are unset, but BASH_LINENO[0] is the line number in the
#   interactive shell.
#
# - Sourced or not: a function executed in the body of a script file will have
#   FUNCNAME[1]="main" in when the file is run using `bash ./file` or
#   FUNCNAME[1]="source" in a sourced file.
#
#

# testing
#             | interactive | ddd() int. |   . ./dotted | bash ./execed
# ------------|-------------|------------|--------------|---------------
# LINENO      |         629 |          2 |            3 |            3
# BASH_LINENO |          () |    [0]=640 |      [0]=642 |        [0]=0
# BASH_SOURCE |          () |   [0]=main | [0]=./dotted | [0]=./execed
# $0          |       -bash |      -bash |        -bash |     ./execed
# FUNCNAME    |   # unbound |    [0]=ddd |    # unbound |    # unbound
# caller      |    # $? = 1 |   640 NULL |     642 NULL |       0 NULL
# caller 0    |    # $? = 1 |   # $? = 1 |     # $? = 1 |     # $? = 1
# caller 1    |    # $? = 1 |   # $? = 1 |     # $? = 1 |     # $? = 1
# ( exit 13 ) |

# trap testing (TODO: finish or move to file)
trap_tester() {
    # avoid printing the trap for interactive completion functions
    # e.g. echo $SO<Tab>
    # - would be nice, but some still print; 'set +o errtrace' silences it
    # - '[[ -t 1 ]]' makes sure STDOUT is open on a terminal.
    trap -- '
        [[ -t 1  &&  -v FUNCNAME[0] ]] && {
            echo "ERR trap from ${FUNCNAME[0]}()" >&2
            { printf '%s' "caller 1: "; caller 1; } >&2
            return
        }
    ' ERR
}


trap-err() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Show a useful message on non-zero return status

        The output differs depending on the context, whether run for the return of
        a function, a sourced file, or a command.

        Usage

        _Case 1_: in the main lines of an interactive shell.

          trap 'trap-err \$?' ERR

          # Consider also something like this. This way, functions will return
          # immediately and print an error when a command returns with non-zero status.
          # However, the test ensures that the ERR trap won't trigger in the interactive
          # shell. Except it does in completion functions, it would be nice if it didn't
          # do that.
          set -o errtrace
          trap '
              [[ -v FUNCNAME[0] ]] && {
                  echo \"traperr from \${FUNCNAME[0]}()\"
                  return
              }
          ' ERR

        _Case 2_: in a function, or used with functrace from an interactive shell.

          # - To prevent the ERR trap 'leaking' into the enclosing shell, set both
          #   an ERR and a RETURN trap (see below).
          # - Using a naked return command in the ERR trap preserves the return status
          #   of the triggering command.

          foo() {
              trap '
                  trap-err \$?
                  return
              ' ERR

              trap '
                  trap - ERR RETURN
                  # also maybe unset -f ...
              ' RETURN
              ...

              # If there are sub-functions, you probably want 'errtrace' but not
              # 'functrace', so that the subfunctions will return immediately and print
              # an error when a command returns with non-zero status, but also

              # extend traps to sub-functions
              shopt -os errtrace    # functions inherit the ERR trap
              #shopt -os functrace   # functions inherit RETURN and DEBUG traps
          }

        Notes and Gotchas

        - Using a naked 'return' call in the ERR trap preserves the return status of the
          command that triggered the trap.

        - Calling 'exit' within an EXIT trap is a special case that skips a recursive
          run of the trap. If it's a naked 'exit' call, the return status is the value
          on entry to the trap.
          ref: [QA](https://unix.stackexchange.com/a/667384/85414)

        - Process substitution, like '<( cmd ... )', runs asynchronously, so \$? is not
          set to the return status of 'cmd'. That makes debugging harder. You can
          use a fifo or some [clever tricks](https://unix.stackexchange.com/a/176703/85414),
          but finding a different way is ideal if the command could fail.

        - Another item to watch for: if you use a subshell during inline initialization
          of a varaible when using 'local' or 'declare' (e.g. \`local foo=\$( cmd ... )\`),
          the return status of the subshell is lost; the local command returns 0
          regardless. So only use inline init with local for very simple cases.
        "
        docsh -TD
        return
    }

    local _rs=$1 && shift
    local _msgs=()

    # Called from sourced file, function, or interactive?
    # - see notes on Bash variables above
    if [[ -n ${FUNCNAME[1]-} ]]
    then
        # source file, contracting HOME to ~
        local _srcfn _callfn _call_ln
        _srcfn=$(  sed "s:^$HOME:~:" <<< "${BASH_SOURCE[1]}" )
        _callfn=$( sed "s:^$HOME:~:" <<< "${BASH_SOURCE[2]:-main}" )

        # offending line
        _call_ln=$( sed "${BASH_LINENO[0]}"'! d' "${BASH_SOURCE[1]}" )

        # determine whether the error was thrown by err_msg
        # - checks for e.g. ' { err_msg ...' or ' [[ ... ]] && { err_msg ...', but also
        #   should match in case statements, like ... ) err_msg ...
        if grep -qE '(^|[[:blank:]]*\[\[.*\]\][[:blank:]]+&&|.*\))([[:blank:]{]+)?err_msg[[:blank:]]+' <<< "$_call_ln"
        then
            # error already reported by err_msg
            return

        elif [[ ${FUNCNAME[1]} == source ]]
        then
            # sourced file
            _msgs+=( "Error $_rs encountered at l. ${BASH_LINENO[0]} of" )
            _msgs+=( "  sourced file $_srcfn" )

        # elif [[ ${FUNCNAME[1]-} == docsh ]]
        # then
        #     # docsh function test to trigger printing docstr and return
        #     echo not implemented

        else
            # function
            _msgs+=( "Return status $_rs encountered in '${FUNCNAME[1]}()'," )
            _msgs+=( "  at l. ${BASH_LINENO[0]} of ${_srcfn}," )
            # below line does not seem reliable...
            _msgs+=( "  as called from ${_callfn} (? l. ${BASH_LINENO[1]}):" )
            _msgs+=( "$_call_ln" "" )
        fi

    else
        # interactive shell (probably), or script
        local _str="main-err: code $_rs"

        [[ -n ${BASH_SOURCE[0]-} ]] &&
            _str+=" in ${BASH_SOURCE[0]}"

        _msgs+=( "$_str" )
    fi

    printf >&2 '%s\n' "${_msgs[@]}"
}
