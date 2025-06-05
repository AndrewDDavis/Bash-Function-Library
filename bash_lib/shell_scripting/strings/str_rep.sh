str_rep() {

    : """Print repetitions of a character or string.

    Usage: str-rep <str> <n>

    E.g. dashes for a table, or spaces for indentation:
      str-rep - 6
      str-rep ' ' 4
	"

    [[ $# -lt 2 || $1 == -h ]] &&
        { docsh -TD; return; }

    local i n=$2

    [ "$n" -ge 0 ] ||
        { err_msg 2 "non-negative integer required, got ${n@Q}"; return; }

    # Safer than 'while (( n-- ))', in case of n=null
    # - NB invalid values (e.g. strings) resolve to 0
    for (( i = 0; i < n; i++ ))
    do
        printf '%s' "$1"
    done
    [[ i -eq 0 ]] || printf '\n'

    # old way:
    # - this uses seq to output the required no. of words, then the format '.0s' to
    #   format them as 0-length words
    #printf -- "$1"'%.0s' $( seq $2 )
}
