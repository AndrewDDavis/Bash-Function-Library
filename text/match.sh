match() {

    : "Test STDIN for match to a regex pattern using awk

    This is similar to grep -q, but can have advantages, e.g. expansion of
    '\n' and '\t'.

    Usage: awk-test 'pattern' <<< test-string

    Returns 0 (true) for a match, or 1 for no match.
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    awk '
        /'"$1"'/ {exit 0}
        {exit 1}
    '
}
