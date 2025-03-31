# alias man to the wrapper func
alias man='man-wrapper'

man-wrapper() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -DT "Limit man page width on wide terminals

        This function is mostly a transparent wrapper for man, except for two features:

          - it limits the width of the displayed page
          - it adds the --nj option to disable full-width justification of the page

        Option: --mw=<n> : width limit in chars (default 88)

        All other arguments are passed to man as usual. To pass -h or --help
        to man, use \`man -- -h\`.

        Notable man options:

          --nj : no justification (ragged-right)
        "
        return 0
    }

    # default
    local _manwidth=88

    local OPT OPTIND=1
    while getopts ':-:' OPT
    do
        # long option: split key=value so that OPT=key and OPTARG=value (may be empty)
        if [[ $OPT == '-' ]]
        then
            OPT=$( cut -d= -f1 <<< "$OPTARG" )
            OPTARG=$( cut -d= -sf2 <<< "$OPTARG" )
        fi

        case $OPT in
            ( mw ) _manwidth=$OPTARG
                   shift
            ;;
            ( * ) break
            ;;
        esac
    done
    [[ $1 == '--' ]] && shift

    # array of environment variables to set
    local -a evars

    # limit width if needed
    if [[ -z ${MANWIDTH:-} && ${COLUMNS:-$(tput cols)} -gt $_manwidth ]]
    then
        evars+=( "MANWIDTH=$_manwidth" )
    fi

    # disable justification
    # - quoting is OK: don't add escaped quotes, they will become part of the value
    # - could escape the $, but then you would need to eval the export line
    evars+=( "MANOPT=${MANOPT:+$MANOPT }--nj" )

    # call man in subshell
    (
        # - or could do ${evars[@]:+export "${evars[@]}"}
        [[ -n ${evars[@]} ]] && export "${evars[@]}"
        command man "$@"
    )
}
