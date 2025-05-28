# dependencies
import_func is_nn_array \
    || return

verb_msg() {

    [[ $# -lt 2  || $1 == @(-h|--help) ]] && {

        : "Print a message to stderr if indicated by the verbosity setting

            Usage: verb_msg <level> \"message body\" ...

            This function compares the value of a variable called '_verb' against the
            'level' argument passed on the command line. If _verb >= level, the message
            is printed to stderr. If more than one string is provided, all are printed,
            separated by newlines. Leading null messages print an empty line, without
            the usual leading context.

            If _verb is not set, or its value is not an integer, it is considered equal
            to 0. The recommended default is to set _verb=1 in the calling function.
            Then the value could be incremented when the user passes a -v flag on the
            command line, or decremented with -q.

            Unlike err_msg, which prints log-style messages and sets a return value,
            this function prints a more subtle context message and always returns true.

            Examples

              # an info message that should usually print
              verb_msg 1 \"triggered a routine\"

              # a message that isn't usually required
              verb_msg 2 \"the value of x is \$x\"

              # may only print with -vv
              verb_msg 3 \"the gg routine returned \$gg\"
        "
        docsh -TD
        return
    }

    # - NB, unset _verb is considered == 0
    [[ ${_verb-} -lt $1 ]] \
        && return

    # remaining args are message strings
    local msgs=( "${@:2}" )
    shift $#

    # print nothing on null input
    is_nn_array msgs || return

    # cleanup routine
    trap '
        unset -f _def_context
        trap - return
    ' RETURN

    _def_context() {

        # NB, within this function, FUNCNAME[2] is the caller
        local i=3
        while [[ $context == _* ]]
        do
            # underscore functions are probably not the context we want
            if [[ -n ${FUNCNAME[i]-} ]]
            then
                context=${FUNCNAME[i]}
            else
                break
            fi
            (( i++ ))
        done

        # report LVL for functions that track nested calls
        # e.g. IMPORT_FUNC_LVL for import_func
        local lvl=${context@U}_LVL
        [[ -v $lvl ]] \
            && context+=" (LVL=${!lvl})"

        # finish context string
        # - also define indent spaces for subsequent lines
        if [[ -z ${context-} ]]
        then
            context='  '
            spcs='  '
        else
            context+=': '

            for (( i=0; i<${#context}; i++ ))
            do
                spcs+=' '
            done
        fi
    }

    # define leading context for message strings
    local context=${FUNCNAME[1]-} spcs=''
    _def_context

    # print empty line for leading null msgs
    local -i n=0
    while [[ -z ${msgs[n]} ]]
    do
        printf >&2 '\n'
        (( ++n ))
    done

    # format and print first content line
    printf >&2 '%s\n' "${context}${msgs[n]}"
    (( ++n ))

    while [[ -n ${msgs[n]-} ]]
    do
        # format and print subsequent lines
        printf >&2 '%s\n' "${spcs}${msgs[n]}"
        (( ++n ))
    done
}
