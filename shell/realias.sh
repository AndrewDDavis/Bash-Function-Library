#!/usr/bin/env bash

realias() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Define an alias, retaining any previous definitions

        Usage: realias <command> <alias-string>

        Checks whether an alias is defined for 'command' in the current shell, then:
        - If no alias is defined, creates one using the supplied values.
        - If an alias exists, and doesn't already contain the supplied alias value, adds the
        new value to the alias.

        NB, this function is meant to be used in rc files (e.g. ~/.bashrc), but cannot be
        used effectively within a shell function. This is because alias definitions in a
        function's body do not take effect until after the function is executed (refer to
        the Bash manual for details). To use a defined alias in a function, refer to the
        'alias_rslv' function.

        Example:

        realias ls 'ls --color'

        # - with no previous alias:
        #   alias ls='ls --color'
        # - if the previous alias was 'ls -h':
        #   alias ls='ls -h --color'
        "
        docsh -TD
        return
    }

    # arg sanity
    [[ $# -eq 2 ]] || return 2

    local cmd=$1
    local al_str=$2
    shift 2

    if ! builtin alias "$cmd" &>/dev/null
    then
        # no current alias definition
        builtin alias "$cmd"="$al_str"

    else
        # alias defined:
        # - do word splitting and quote removal on the old and new alias strings, while
        #   respecting quotes and escapes.
        # - NB, not recursively resolving the alias for cmd, only redifining the alias;
        #   the alias_rslv function can resolve recursively.
        local al_words=() new_words=()

        str_split al_words "${BASH_ALIASES[$cmd]}"
        str_split new_words "$al_str"

        # identify the command, after any env var assignments
        # - NB the BASH_ALIASES[$cmd] entry may contain cmd, but not ecessarily;
        #   e.g. my 'ls-perms' alias simply points to the function 'ls-acl', and the
        #   alias ls-bindings='compgen-match binding'.

        local cmd i j k l
        i=$( array_match -n al_words '^[^=]+$' ) ||
            { err_msg 3 "no command found in al_words: '${al_words[*]}'"; return; }
        cmd=${al_words[$i]}

        # sanity: ensure the command has not changed
        j=$( array_match -nF new_words "$cmd" ) ||
            { err_msg 4 "not found in new alias string: '$cmd'"; return;  }

        # drop existing al_words elements that match new_words
        # - this ensures args are added at the end, where they usually take precedence
        for k in "${!new_words[@]}"
        do
            [[ $k == $j ]] && continue

            # - use array_strrepl here?
            #   just need to deal with possible error condition
            if l=$( array_match -nF -- al_words "${new_words[$k]}" )
            then
                unset al_words[$l]
            fi
        done

        # insert var assns before the command
        [[ $j -gt 0 ]] &&
            array_irepl al_words $i "${new_words[@]:0:$j}" "$cmd"

        # add args after the command to the end
        [[ ${#new_words[@]} -gt $((j+1)) ]] &&
            al_words+=( "${new_words[@]:$((j+1))}" )

        # recreate the alias string
        local w

        array_reindex al_words
        al_str=${al_words[0]}

        if [[ ${#al_words[@]} -gt 1 ]]
        then
            for w in "${al_words[@]:1}"
            do
                al_str+=" $w"
            done
        fi

        # redefine the alias in the shell's list
        if [[ -n $al_str ]]
        then
            builtin alias "$cmd"="$al_str"
        else
            err_msg 3 "empty al_str"
            return
        fi


        # vvv old code
        #     was simpler, but didn't work for some cases

            # local alstr
            # alstr=${BASH_ALIASES[$1]}

            # # do nothing if provided string is already part of the alias
            # if [[ $alstr == *$2* ]]
            # then
            #     return 0

            # # ensure the substitution is possible
            # elif [[ $alstr == *$1* ]]
            # then
            #     # sub, respecting the order: env vars should come first
            #     builtin alias "$1"="${alstr/$1/$2}"

            # else
            #     # complain
            #     type "$1"
            #     return 3
            # fi
    fi
}
