#!/bin/bash

vars-grep() {

    [[ $# -gt 0  &&  $1 == @(-h|--help) ]] && {

        : "Print variables that match a pattern in their name, attributes, and/or value

        Usage: vars-grep [-a] [grep-opts] [pattern]

        Notes

          - With option \`-a\`, match against the variable names, values, and attributes,
            as defined by \`declare\` (or \`typeset\`). Otherwise, only match against
            the names.

          - All other arguments are passed to \`grep\`, in order to filter the output of
            \`declare -p\`. The \`greps\` function is used to provide case-insensitive
            pattern matching, unless the pattern contains an uppercase letter (smart-
            case).

          - Whereas \`ls-vars | grep -i zip\` will print a list of variable names that
            contain 'zip' (case-insensitive), \`vars-grep -a -i zip\` will print a list
            of variables, with their attributes, that contain 'zip' (case-insensitive)
            in their name or value.

        Examples

          # arrays
          vars-grep ''
        "
        docsh -TD
        return
    }

    local _all
    [[ ${1-} == -a ]] &&
        { _all=1; shift; }

    # no filtering if no args
    [[ $# -eq 0 ]] &&
        set -- '^'

    local grep_cmd sed_cmd
    grep_cmd=$( type -P grep )
    sed_cmd=$( type -P sed )

    [[ -n $( command -v greps ) ]] &&
        grep_cmd=greps

    if [[ -n ${_all-} ]]
    then
        declare -p \
            | "$grep_cmd" "$@" \
            | "$sed_cmd" 's/=.*//'
    else
        declare -p \
            | "$sed_cmd" 's/=.*//' \
            | "$grep_cmd" "$@"
    fi
}
