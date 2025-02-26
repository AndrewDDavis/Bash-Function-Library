
touch-wr() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Make a file world-readable after creation with touch

        Usage: touch-wr [tch-opt ...] <file-name ...>

        Options

          -f : force action, even if the file exists

        All other options are passed to touch.
        "
        return 0
    }

    # touch-wr options
    local force

    # options for touch
    local tch_opts=()

    while [[ ${1:-} == -* ]]
    do
        if [[ $1 == '--' ]]
        then
            shift
            break

        elif [[ $1 == '-f' ]]
        then
            # should really use getopts or a better scheme for e.g. -abcfde
            force=force
            shift

        elif [[ $1 != --*  &&  $1 == -*@(d|r|t) ]]
        then
            # touch options that take an arg

            tch_opts+=( "$1" "$2" )
            shift 2

        else
            tch_opts+=( "$1" )
            shift
        fi
    done

    # main loop
    local fn

    for fn in "$@"
    do
        if [[ -e "$fn" && -z "${force:-}" ]]
        then
            err_msg 2 "file exists: $fn"
            return 2
        fi

        (
            set -x
            touch "${tch_opts[@]}" "$fn" && \
                chmod o+r "$fn"
        )
    done
}
