rename-nameswap() {

    : "change filename so that \"the file name\" becomes \"name, the file\""

    [[ $# -eq 0 || $1 == -h ]] &&
        { docsh -TD; return; }

    local bn dn bn_words obn ofn

    for fn in "$@"
    do
        bn=$( command basename "$fn" )
        dn=$( command dirname "$fn" )

        # place filename words in array
        # IFS=$'\n' read -ra bn_words -d '' < <( compgen -W "$bn" )
        str_split bn_words "$bn"

        # generate new basename
        c=$(( ${#bn_words[@]} - 1 ))
        obn="${bn_words[-1]}, ${bn_words[@]:0:$c}"

        ofn="$dn/$obn"

        # move file into place
        command mv -vi "$fn" "$ofn"
    done
}

rename-titlecase() {

    : "change filename words to title-case"

    [[ $# -eq 0 || $1 == -h ]] &&
        { docsh -TD; return; }

    local bn dn bn_words obn ofn1 ofn2

    for fn in "$@"
    do
        bn=$(command basename "$fn")
        dn=$(command dirname "$fn")

        # read filename words as array
        # IFS=$'\n' read -ra bn_words -d '' < <( compgen -W "$bn" )
        str_split bn_words "$bn"

        # generate new basename
        obn=${bn_words[@]@u}

        # use a 2-step rename for case-insensitive filesystems (macOS)
        ofn1="$dn/_rn_$obn"
        ofn2="$dn/$obn"

        command mv -vi "$fn" "$ofn1" &&
            command mv -vi "$ofn1" "$ofn2"
    done
}
