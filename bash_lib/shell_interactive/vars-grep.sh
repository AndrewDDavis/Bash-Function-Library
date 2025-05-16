# deps (optional)
import_func greps

vars-grep() {

    [[ $# -gt 0  && $1 == @(-h|--help) ]] && {

        : "Print variables that match a pattern

        Usage: vars-grep [-a] [grep-opts] [pattern]

        By default, this function compares the pattern with variable names set in the
        current shell, and prints the matches. If the greps function is available, it
        will be used to provide smart-case matching. The -E flag is added by default.

        Options

          -a
          : Match against variable names, values, and attributes, as output by the
            declare or typeset builtins.

        Notes

          - Beyond the -a option, all arguments are passed to grep, which is used to
            filter the output of 'declare -p'. The 'greps' wrapper function is
            called, so that smart-case pattern matching is used (case-insensitive
            unless the pattern contains uppercase letters).

          - For name-only searches, 'ls-vars | grep -i zip' will print a list of
            variable names that contain 'zip' (case-insensitive). OTOH,
            'vars-grep -a zip' will match against the variable names and values.

        Examples

          # arrays
          vars-grep -a '^declare -[^ ]*a[^ ]* '
        "
        docsh -TD
        return
    }

    # use double-underscore variable names so they don't interfere with those of the
    # shell environment
    local __all
    [[ ${1-} == -a ]] &&
        { __all=1; shift; }

    # no filtering if no args
    [[ $# -eq 0 ]] &&
        set -- '^'

    local __grep_cmd \
        __sed_cmd \
        __dec_cmd \
        __var_filt

    __dec_cmd=( builtin declare -p )

    if [[ -n $( command -v greps ) ]]
    then
        __grep_cmd=( greps -E )
    else
        __grep_cmd=( "$( builtin type -P grep )" -E )
    fi

    __sed_cmd=( "$( builtin type -P sed )" )
    __sed_cmd+=( 's/=.*//' )

    # filter local vars from results
    __var_filt=( "${__grep_cmd[@]}" -Ev '__all|__grep_cmd|__sed_cmd|__dec_cmd|__var_filt' )

    # pattern arg and options for grep
    __grep_cmd+=( "$@" )
    shift $#


    if [[ -v __all ]]
    then
        "${__dec_cmd[@]}" \
            | "${__var_filt[@]}" \
            | "${__grep_cmd[@]}" \
            | "${__sed_cmd[@]}"

        local rs=${PIPESTATUS[2]}
    else
        "${__dec_cmd[@]}" \
            | "${__var_filt[@]}" \
            | "${__sed_cmd[@]}" \
            | "${__grep_cmd[@]}"

        local rs=${PIPESTATUS[3]}
    fi

    return "$rs"
}
