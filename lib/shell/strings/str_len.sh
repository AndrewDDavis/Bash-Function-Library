str_len() {

    : "Print lengths of strings passed as input, 1 per line"

    # TODO: ignore ANSI formatting characters

    [[ $# -eq 0  || $1 == -h ]] &&
        { docsh -TD; return; }

    local s

    for s in "$@"
    do
        printf '%s\n' "${#s}"
    done
}
