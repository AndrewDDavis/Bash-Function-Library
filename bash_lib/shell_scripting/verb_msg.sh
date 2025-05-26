verb_msg() {

    [[ $# -lt 2  || $1 == @(-h|--help) ]] && {

        : "Print a message to stderr if indicated by the verbosity setting

            Usage: verb_msg <level> \"message body\" ...

            This function compares the value of a variable called '_verb' against the
            'level' argument passed on the command line. If _verb >= level, the message
            is printed to stderr. If more than one string is provided, all are printed,
            separated by newlines.

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

    # this construct efficiently ensures return status is 0
    # - unset _verb is considered == 0
    [[ ${_verb-} -lt $1 ]] || {

        local i=1 context=${FUNCNAME[1]-}
        while [[ $context == _* ]]
        do
            # underscore functions are probably not the context we want
            (( ++i ))
            if [[ -n ${FUNCNAME[i]-} ]]
            then
                context=${FUNCNAME[i]}
            else
                break
            fi
        done

        # report LVL for functions that track nested calls
        # e.g. IMPORT_FUNC_LVL for import_func
        local lvl=${context@U}_LVL
        [[ -v $lvl ]] \
            && context+=" (LVL=${!lvl})"

        # format and print first line
        if [[ -z ${context-} ]]
        then
            context="  "
        else
            context+=": "
        fi
        printf >&2 '%s\n' "${context}$2"
        shift 2

        if (( $# > 0 ))
        then
            # format and print subsequent lines
            local spcs=''
            for (( i=0; i<${#context}; i++ ))
            do
                spcs+=' '
            done

            while (( $# > 0 ))
            do
                printf >&2 '%s\n' "${spcs}$1"
                shift
            done
        fi
    }
}
