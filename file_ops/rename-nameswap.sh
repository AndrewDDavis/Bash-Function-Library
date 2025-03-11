import_func str_split \
    || return 63

rename-nameswap() {

    : "change filename so that \"the file name\" becomes \"name, the file\""

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local bn dn bn_words c obn ofn

    for fn in "$@"
    do
        bn=$( basename "$fn" )
        dn=$( dirname "$fn" )

        # place filename words in array
        # IFS=$'\n' read -ra bn_words -d '' < <( compgen -W "$bn" )
        str_split bn_words "$bn"

        # generate new basename
        c=$(( ${#bn_words[@]} - 1 ))
        obn="${bn_words[-1]}, ${bn_words[*]:0:$c}"

        ofn="$dn/$obn"

        # move file into place
        command mv -vi "$fn" "$ofn"
    done
}
