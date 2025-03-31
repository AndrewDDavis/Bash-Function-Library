man-search() {

    : "Report man pages that match a keyword

        Usage: man-search [options] [[--] man-options] <search-term>

        This function prints the manpage names and short descriptions that match the
        search term. It uses 'man -k' to perform the search, which acts like apropos.
        Search terms are usually treated as a regular expressions, but this may be
        modified using the options below. The search is case-insensitive, unless the
        -I option is passed.

        If the -n (name) mode is used, the search terms are only matched against
        manpage names, not their descriptions. This calls 'man -f --regex', which acts
        like whatis.

        If the -g (global) mode is used, the search terms are matched against the long
        description sources. This mode treats the pattern as a simple string by
        default, unless regex is requested. This calls 'man -Kw' to obtain the matching
        manpage paths, then prints the corresponding names and short descriptions.

        Options

          -g : global search mode
          -n : name search mode
          -r : regex search matching substring (default)
          -w : wildcard (glob) search matching whole word
          -e : match against exact page names and descriptions
          -- : pass remaining args to man
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local man_cmd
    man_cmd=( "$( builtin type -P man )" ) \
        || return 9

    # opt-parsing
    local _g _n

    local flag OPTARG OPTIND=1
    while getopts ":gnrwe-" flag
    do
        case $flag in
            ( g )  _g=1 ;;
            ( n )  _n=1 ;;
            ( r )  man_cmd+=( --regex ) ;;
            ( w )  man_cmd+=( --wildcard ) ;;
            ( e )  man_cmd+=( --exact ) ;;
            ( - )
                # preserve long option for man
                # - OPTIND did not advance
                break
                ;;
            ( \? )
                # preserve short option for man
                # - OPTIND advanced if flag was alone
                p=$(( OPTIND-1 ))
                [[ ${!p} == -$OPTARG ]] &&
                    (( OPTIND-- ))
                break
            ;;
        esac
    done
    shift $(( OPTIND-1 ))

    if [[ -v _n ]]
    then
        # name search
        # - NB, --names-only implied with man -f / whatis
        man_cmd+=( -f --regex )
        "${man_cmd[@]}" "$@" \
            || return

    elif [[ ! -v _g ]]
    then
        # short search
        # - NB, --names-only has no effect with -k / apropos
        # - uses regex by default
        man_cmd+=( -k )
        "${man_cmd[@]}" "$@" \
            || return

    else
        # global search, returning paths to man files
        local paths p
        man_cmd+=( -Kw )

        # man returns 16 for nothing found, and this func should too
        IFS=$'\n' read -ra paths -d '' < \
            <( "${man_cmd[@]}" "$@" && printf '\0' ) \
            || { wait $!; return; }

        # extract name and short description from man files
        for p in "${paths[@]}"
        do
            # extract command name and short desc from manpage
            local _filt mp_line mp_name mp_desc mp_secn

            # Usage of man -l:
            #   - e.g. man -l -Tutf8 ./usr/share/man/man1/uniq.1.gz > uniq_manpage.txt
            #   - usually, man passes the output to the less pager
            #   - when redirecting the output, man writes plain text to the file
            #   - if using -t, man formats it for groff, which is unreadable
            #   - if using -Tutf8, man writes formatting escape sequences (e.g. [1m for bold text) within the file

            # sed filter to parse various formats for the name and descrip
            _filt='
                /N(AME|ame)/ {
                    n
                    # if name and desc on one line, print the line
                    / (—|-) / {p; q;}

                    # otherwise, combine the name line with the next line
                    N
                    s/-\n[[:blank:]]*/- /
                    s/\n[[:blank:]]*//
                    p; q
                }
            '
            mp_line=$( command sed -nE "$_filt" < <( command man -l "$p" 2>/dev/null ) )

            _filt='
                s/^[[:blank:]]*(.*) (—|-) (.*)[[:blank:]]*$/\1/
            '
            mp_name=$( command sed -E "$_filt" <<< "$mp_line" )

            _filt='
                s/^[[:blank:]]*(.*) (—|-) (.*)[[:blank:]]*$/\3/
            '
            mp_desc=$( command sed -E "$_filt" <<< "$mp_line" )

            # section number
            mp_secn=$( basename "${p%.gz}" )
            mp_secn=${mp_secn##*.}

            # report, adding section number
            printf '%20s - %s\n' "$mp_name ($mp_secn)" "$mp_desc"
        done
    fi
}
