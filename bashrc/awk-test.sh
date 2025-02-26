awk-test() {
    : "Test a regex using awk

    This can have advantages over grep, e.g. expansion of '\n' and '\t'.

    Usage: awk-test 'pattern' <<< test-string
    "

    awk '
        /'"$1"'/ {exit 0}
        {exit 1}
    '
}
