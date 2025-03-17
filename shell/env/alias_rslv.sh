alias_rslv() {

    # function docs
    [[ $# == 0  ||  $1 == -h ]] && {

        : "resolve alias(es) recursively

        Usage: alias_rslv [-e] <command> <array-name>

        Checks whether an alias is defined for 'command' in the current execution
        environment.
        - If not, 'array-name' will contain only 1 element, the command itself.
        - If so, 'array-name' will contain the command alias split into words, including
          any arguments and variable definitions in the alias. Furthermore, if the
          resulting command is an alias, it is resolved recursively until no new command
          results from the process.

        This function allows the use of command aliases in shell functions. Aliases are
        expanded in functions if they are defined when the function definition is read,
        and the shell is interactive, or the 'expand_aliases' option is set at that
        time. This is not usually the case when the shell is executing rc files and
        reading function definitions at startup.

        Care is needed to handle aliases that include variable assignments before the
        command, e.g. alias ls='LC_COLLATE=en_CA.utf8 ls --color=auto'. When this
        captured in a variable, even when split into an array, the shell won't run it as
        usual, since A=B is interpreted as a command. In this case, 'env' can be added
        to the start of the command array, e.g.:

          [[ \${cmd_words[0]} == *=* ]] &&
              cmd_words=( env \"\${cmd_words[@]}\" )

        The '-e' option to this function adds 'env' as the first element of the array,
        if the first element would otherwise be a variable assignment.

        Examples

          alias_rslv ll ls_cmd
          # ls_cmd may be: ( LC_COLLATE=C.utf8 ls --color=auto -lh )
        "
        docsh -TD
        return
    }

    # env option
    local _e=''
    [[ $1 == -e ]] && { _e=1; shift; }

    # posn args
    [[ $# -eq 2 ]] || return 2

    local cmd=$1
    local -n al_words=$2
    shift 2

    # return false for no current alias definition
    builtin alias "$cmd" &>/dev/null \
        || return 1

    # Recursively resolve the alias, up to 100 iterations
    al_words=( "$cmd" )
    local i=0 new_words=() new_cmd

    while builtin alias "$cmd" &>/dev/null
    do
        # fetch defined alias and split into words, respecting quoting
        str_to_words -q new_words "${BASH_ALIASES[$cmd]}"

        # replace cmd in the al_words array with its alias words (e.g. ll -> ls -l)
        array_strrepl al_words "$cmd" "${new_words[@]}"

        # identify the new command word, after any env var assignments
        new_cmd=$( array_match -p new_words '^[^=]+$' )

        # detect recursive alias
        [[ $new_cmd == "$cmd" ]] && break
        cmd=$new_cmd

        # limit runaway loop
        (( i++ ))
        [[ $i -gt 99 ]] &&
            { err_msg 99 "too many iterations"; return; }
    done

    # add env?
    if [[ -n $_e  &&  ${al_words[0]} == *=* ]]
    then
        al_words=( env "${al_words[@]}" )
    fi
}
