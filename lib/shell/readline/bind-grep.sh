# deps
import_func alias-resolve array_strrepl \
    || return 63

bind-grep() {

    : "Search readline keybindings

      bind-grep [grep-options] 'pattern'
      bind-grep -k 'string'

    This function filters a list of readline keybindings for functions, macros, and
    shell commands, and reformats the output to improve readability. Unless using '-k',
    all arguments are passed through to the 'grep' command. By default, the '-E' and
    '-i' options are included to match using ERE patterns in a case-insensitive manner.
    bind-grep removes 'self-insert' lines from bind's output.

    When using the '-k' form, bind-grep prints bindings to the supplied string. This is
    often a single character (e.g. 'n'), but may be a sequence (e.g. '^[[5~' for PgUp).
    If the string contains '^[', which represents the escape character, it is removed.
    This allows matching to the sanitized string produced from bind's output. When using
    '-k', matching is performed by 'awk', in the same way that 'grep -iE' would.
    Unmatched opening brackets and parentheses ('[', '('), which would cause an error,
    are automatically escaped by bind-grep. Other regex meta-chars ('\', '^', '$', '.',
    '|', '*', '+', '?') should be escaped with '\' to be matched literally.

    Most characters, including all letters and digits, are regular expressions that match
    themselves. To match literal meta-characters such as '.', '*', '(', '[', '|', '{',
    '^', and '$', they should be quoted by preceding with a backslash or enclosing in
    square brackets, e.g. '\*' or '[.]'. This includes the backslash character itself,
    which is also double printed in bind's double-quoted output; thus, to search for
    bindings on '\', you would use -k '\\\\' or -k '[\][\]'.

    Other common queries that can be accomplished using bind:

    - To filter a list of the **readline function-names** without showing their bindings,
      you can use 'bind -l | grep ...'.
    - To filter a list of **readline variables** and print their state, you can use
      'bind -v | grep...'.
    - To query which keys invoke a function, you can use 'bind -q <name>'. The return
      status also indicates whether the function is bound to any keys.

    Examples

      # print bindings that have to do with history or completion
      bind-grep 'hist|comp'

      # print bindings on 'n'
      bind-grep -k n
      # '\\en', '\\e\\C-n', '\\C-x\\C-n', etc.

      # print bindinds to '{'
      bind-grep -k '\{'
    "

    [[ $# -eq 0  ||  $1 == -h ]] &&
        { docsh -TD; return; }

    local _k grep_args=( -Ei )

    local flag OPTARG OPTIND=1
    while getopts ':k:' flag
    do
        case $flag in
            ( k )
                # filter:
                # - escape unmatched brackets and parentheses
                # - remove escape sequence ('^['), e.g. in '^[[5~' for PgUp
                _filt='
                    s/\^\[//g
                    s/(^|[^\])(\[[^]]*|\([^)]*)$/\1\\\2/
                '
                OPTARG=$( sed -E "$_filt" <<< "$OPTARG" )
                _k=$OPTARG
                ;;
            ( '?' )
                grep_args+=( -"$OPTARG" )
                ;;
        esac
    done

    # preserve '--'
    (( OPTIND-- ))
    [[ $OPTIND -gt 0  && ${!OPTIND} == '--' ]] &&
        (( OPTIND-- ))
    shift $OPTIND

    grep_args+=( "$@" )


    # gather the binding definitions for functions, macros, and shell commands
    local binddefs_str _filt

    binddefs_str=$( builtin bind -p )
    binddefs_str+=$( builtin bind -s )
    binddefs_str+=$( builtin bind -X )

    # formatting
    _filt='
        # remove empty lines and self-insert lines
        /^$/ { next; }
        /: self-insert$/ { next; }

        # improve formatting of (not bound) lines
        /^# .*\(not bound\)$/ {
            sub(/ \(not bound\)$/, "")
            sub(/^#/, "# (none):")
            next
        }

        # align function names
        { printf "%-10s : %s\n", $1, $2; }
    '
    binddefs_str=$( command awk -F ': ' "$_filt" - <<< "$binddefs_str" )


    if [[ -n ${_k-} ]]
    then
        # with -k, search only in bindings

        # awk beats sed for this appliction:
        # - you can store the original line as a variable, and still match against
        #   the scrubbed key-string; or use a function, etc. Then you don't have to
        #   bother with line numbers and arrays, etc., as you would with sed.
        # - also you can pass the _k variable in using -v, and keep the program in
        #   single-quotes, which simplifies having to escape some chars.

        _filt='
            # ignore (not bound) lines
            /^# / { next; }

            match_scrubbed( $0, k ) { print; }

            function match_scrubbed( s, c ) {

                # strip quotes, meta keys, and everything after colon
                gsub(/(^"|"[[:blank:]]+: .+$|\\C-|\\e)/, "", s)

                # match, case-insensitive, ERE
                return ( tolower(s) ~ tolower(c) ? 1 : 0 )
            }
        '
        command awk -v "k=${_k}" "$_filt" <<< "$binddefs_str"

    else
        # otherwise, grep the whole line

        # Use the calling shell's alias for grep, if any (e.g. 'grep --color=auto')
        local grep_cmd
        alias-resolve grep grep_cmd \
            || grep_cmd=( grep )

        array_strrepl grep_cmd grep "$( builtin type -P grep )"

        "${grep_cmd[@]}" "${grep_args[@]}" <<< "$binddefs_str"
    fi


    # improve formatting of (not bound) lines
    # _filt='
    #     /^#.*(not bound)$/ {
    #         s/ (not bound)$//
    #         s/^#/# (none):/
    #     }
    # '
    # binddefs_str=$( command sed "$_filt" <<< "$binddefs_str" )


#         # array of matching line numbers (1-based)
#         local match_lines=()
#         _filt="
#             # ignore (not bound) lines
#             /^# / d
#
#             # strip quotes, meta keys, and everything after colon
#             s/(^\"|\": [^:]+\$|\\\\C-|\\\\e)//g
#
#             # match
#             /$_k/I =
#         "
#         match_lines=( $( command sed -nE "$_filt" <<< "$binddefs_str" ) )
#
#         # to match with grep instead of sed or awk, use '-n' to print the line no.s
#         # - in my test, the result is identical to the sed matching
#         # match_lines=( $( command grep "${grep_args[@]}" -n -e"$_k" <<< "$bound_chars" |
#         #                      command sed -E 's/([0-9]+):.*/\1/' ) )
#
#         # convert defs str to array
#         local m binddefs_arr=()
#         IFS='' mapfile -t -O1 binddefs_arr <<< "$binddefs_str"
#
#         # print matching lines
#         for m in "${match_lines[@]}"
#         do
#             printf '%s\n' "${binddefs_arr[$m]}"
#             sed -n "$m p" <<< "$bound_chars"
#         done


#     if false
#         # testing ways to match
#         # - could use sed to print each line from the array, but that seems inefficient
#
#         # make an array with indices of the matching line numbers
#         local m ms=()
#         for m in "${match_lines[@]}"
#         do
#             ms[$m]=a
#         done
#
#         # step through the string line-by-line and test
#         local i=1
#         while IFS='' read -r line
#         do
#             [[ -v ms[$i] ]] &&
#                 printf '%s\n' "$line"
#             (( i++ ))
#
#         done <<< "$binddefs_str"
#
#         # awk way: make an array with indices matching the line numbers
#         awk_prgm='
#             BEGIN {
#                 # split the string into an array of line nums
#                 split(s, A)
#
#                 # make the line nums the index, so we can use "in"
#                 for (i in A)
#                     B[A[i]] = ""
#             }
#             # print matching lines
#             (NR in B) {print}
#         '
#         awk -v s="$lns" "$awk_prgm" <<< "$binddefs_str"
#
#         # another awk way
#         # pattern string of line numbers that match
#         match_ptn=$( sed -nE "/$_k/I =" | head -c'-1' | tr '\n' '|' )
#         # - maybe make an awk script out of the line numbers
#         #   like 'NR ~ /^1|2|3$/ {print}'
#         #   or the in operator: 'NR in array', with line numbers as array subscripts
#     fi
}
