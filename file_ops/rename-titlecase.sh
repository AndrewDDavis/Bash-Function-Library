import_func str_split \
    || return 63

rename-titlecase() {

    : "Change filename words to title-case"

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local bn dn bn_words obn ofn1 ofn2

    for fn in "$@"
    do
        bn=$( basename "$fn" )
        dn=$( dirname "$fn" )

        # read filename words as array
        # IFS=$'\n' read -ra bn_words -d '' < <( compgen -W "$bn" )
        str_split bn_words "$bn"

        # generate new basename, using uppercase operator
        obn=${bn_words[*]@u}

        # use a 2-step rename for case-insensitive filesystems (macOS)
        ofn1="$dn/_rn_$obn"
        ofn2="$dn/$obn"

        command mv -vi "$fn" "$ofn1" \
            && command mv -vi "$ofn1" "$ofn2"
    done
}
