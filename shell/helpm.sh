#!/bin/bash

# Use help bash-completion for helpm
# - NB complete -p help -> complete -F _comp_cmd_help help
#complete $(complete -p help | sed 's/^complete //; s/help$/helpm/')

# TODO:
# - completion

helpm() {

    : "Display help pages for shell builtins or functions in a pager

    Uses the value of \$PAGER or 'less', with formatting as if they're man pages. Uses
    'docsh' to get the help text for functions.

    Usage: helpm <command>
    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    [[ $# -gt 1 ]] &&
        { err_msg 2 "too many args"; return; }

    local cmd types _b _f _k

    cmd=$1
    shift

    # check command type
    types=$( type -at "$cmd" )

    command grep -q 'builtin' <<< "$types" && _b=1
    command grep -q 'function' <<< "$types" && _f=1
    command grep -q 'keyword' <<< "$types" && _k=1

    if [[ ( -n ${_b-} || -n ${_k-} )  &&  -n ${_f-} ]]
    then
        err_msg w "'$cmd' is both a function and a shell builtin or keyword"

    elif [[ -z ${_b-}  && -z ${_f-}  && -z ${_k-} ]]
    then
        err_msg 2 "no matches for command: '$cmd'"
        return
    fi

    if [[ -n ${_f-} ]]
    then
        # function
        local docsh_txt

        if docsh_txt=$( docsh -TDf "$cmd" )
        then
            command less -iR <<< "$docsh_txt"
        else
            err_msg w "docsh error for function '$cmd'"
        fi
    fi

    if [[ -n ${_b-}  || -n ${_k-} ]]
    then
        # builtin or keyword
        local help_txt filt
        help_txt=$( builtin help -m "$cmd" )

        # use sed to make the headings bold, like a man page
        # - for more, see the str_csi_vars function:
        #   [[ -z ${_cbo-} ]] && str_csi_vars -pd
        # - not using _cbo, as it includes the prompt-specific \[...\]
        local _bld _rsb _rst
        _bld=$'\e[1m'
        _rsb=$'\e[22m'
        _rst=$'\e[0m'

        filt="s/^([[:upper:] ]+)\$/${_bld}\1${_rsb}/"

        help_txt=$( sed -E "$filt" <<< "$help_txt" )

        # NB, default user options for less will be respected, since they're in the
        # exported variable 'LESS', rather than an alias.
        # - -R ensures that the text style characters will be respected.
        command less -R <<< "$help_txt"
    fi
}
