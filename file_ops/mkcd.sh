# shellcheck shell=bash

mkcd() {

    [[ $# -ne 1 || $1 == @(-h|--help) ]] && {

        : "Make dir + cd in one step

        Usage: mkcd <path>

        - The argument is a path to a directory that will be created if it does not exist.
        "
        docsh -TD
        return
    }

    mkdir -pv "$1"
    cd "$1"
}
