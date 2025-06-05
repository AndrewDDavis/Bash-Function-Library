# Sort command

sort-noansi() {

    [[ $# -gt 0  && $1 == @(-h|--help) ]] && {

        : """Sort while ignoring ANSI escape sequences

          - Uses awk to sort the text provided on STDIN.
          - Any options provided are passed to sort.
        """
        docsh -TD
        return
    }

    # Use awk and sort
    # - the first awk command duplicates the first field and strips out the ANSI bits
    # - the last part strips out that added field
    # - from https://unix.stackexchange.com/a/157971/85414

    awk '{s=$0; gsub(/\033\[[ -?]*[@-~]/,"",s); print s "\t" $0}' \
        | sort "$@" \
        | cut -f 2-
}
