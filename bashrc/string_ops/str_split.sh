str_split() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Split string into words, respecting quoting and escaped whitespace

        Usage: str_split [-q] <array-name> [string ...]

        This function uses a call to 'xargs' to split a string and place the resulting
        words into an array. Whitespace and newlines within the string are preserved
        when they are escaped with quotes or '\\'. If no string is supplied on the
        command line, STDIN is used. If multiple string arguments are supplied, they are
        considered together, so that multiple arguments may be combined into one array
        element if they are connected by quotes.

        Example: str_split ls_cmd \"\${BASH_ALIASES[ls]}\"

        Options

          -q : suppresses the warning when the array is not empty.

        Notes

        Word splitting into an array can be done in several ways, usually by (naively)
        letting the shell split on spaces in the array definition, or using \`'eval'\`.
        However, these are both subject to glob expansions and other avenues of code
        execution performed by the shell, which are often unwanted and may be dangerous.
        Consider this example, running in a directory with files 'x', 'y', and 'z':

          string='abc def \"g h\" \"*\" * \$(echo pwned)'

        Using str_split safely splits the string into words, keeping 'g' and 'h'
        together in one word, having two words of only '*', and two words at the end
        consisting of '\$(echo' and 'pwned)':

          str_split arr <<< \"\$string\"

        or

          str_split arr \"\$string\"

        On the other hand, the following code splits the third word into '\"g' and 'h\"',
        and expands the glob so that 'x', 'y', and 'z' are array elements:

          arr=( \$string )

        Using eval on the quoted string keeps 'g' and 'h' together, but still expands
        the unquoted glob, and even runs the command, so the last array element is just
        'pwned':

          eval arr=( \"\$string\" )

        A safer strategy is to use \`read\` or \`mapfile\` to avoid glob expansions, e.g.:

          read -ra arr <<< \"\$string\"

        However, this still does not respect quoting within the string when splitting
        it into words, and gets tricky if newlines are involved.
        "
        docsh -TD
        return
    }

    # verbosity
    local _v=1
    [[ $1 == -q ]] &&
        { (( _v-- )); shift; }

    # nameref to the array variable
    local -n _arr=$1 || return
    shift

    # read stdin if necessary
    # - don't be tempted to use $( < /dev/stdin ), as [noted](https://unix.stackexchange.com/a/716439/85414)
    [[ $# -eq 0 ]] &&
        set -- "$( cat )"


    # Clear the array
    [[ $_v -gt 0 ]] && {
        # - check and warn, avoiding unbound variable on ${#_arr[@]}
        [[ -n ${_arr[@]} ]] &&
            { err_msg w "clearing non-empty array '${!_arr}'"; }
    }
    _arr=()


    # Safely populate the array
    # - This uses xargs to (re-)evaluate the string, without calling (eeevil) eval.
    # - And it uses null characters to delimit items, which allows anything to be within
    #   them, as long as they're properly quoted.
    # - Nulling IFS is also necessary to prevent stripping of leading and trailing
    #   whitespace in the fields.
    # - For other alternatives, refer to 'Force Word Splitting in Bash' in my Shell
    #   Scripting notes.

    if [[ -n $( command -v mapfile ) ]]
    then
        # Use the mapfile builtin (AKA readarray in newer Bash)
        IFS='' mapfile -td '' _arr < \
            <( xargs printf '%s\0' <<< "$@" )

    else
        # Use read in classic Bash
        local item

        while IFS='' read -rd '' item
        do
            _arr+=( "$item" )

        done < \
            <( xargs printf '%s\0' <<< "$@" )
    fi

    # check return status of the process substitution
    local xa_pid=$!
    wait $xa_pid || {
        err_msg $? "error in background process"
        return
    }
}
