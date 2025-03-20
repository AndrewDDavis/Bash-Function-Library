# Functions for man pages and builtin command help

man-paths() {
    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "Show paths of matching man pages"
        return 0
    }

    man -aw "$@"
}
alias man-where="man-paths"

man-search() (

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Search for keywords in names and short-descriptions of man pages

        Options

          -g : global search (long description sources), using simple strings by default,
               or regex if requested.
          -n : search names only
          -r : regex search matching substring
          -w : wildcard (glob) search matching whole word
          -- : pass remaining args to man

        Options passed to man

          -k : Search man page names and short descriptions for keyword as regular
               expression, print any matches. Equiv. to apropos (default).
          -f : show short descriptions of matching man pages (equiv. to whatis)
        "
        return 0
    }

    _search_type=short
    man_opts=()

    local -i OPTIND=1
    while getopts "gn-" OPT
    do
        case $OPT in
            ( g )  _search_type=global ;;
            ( n )  man_opts+=( --names-only ) ;;
            ( r )  man_opts+=( --regex ) ;;
            ( w )  man_opts+=( --wildcard ) ;;
            ( - )  break ;;
            ( * )  break ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    if [[ $_search_type == short ]]
    then
        man_opts+=( -k )
        man "${man_opts[@]}" "$@"

    elif [[ $_search_type == global ]]
    then
        # global search, but return paths to man files
        man_opts+=( -Kw )

        IFS=$'\n' read -ra paths -d '' < <( man "${man_opts[@]}" "$@" ) || {
            # read returns status 1 at EOF
            s=$?
            [[ $s -eq 1 ]] || ( exit $s; )
        }

        # extract name and short description from man files
        for p in "${paths[@]}"
        do
            # extract and split command name and short desc
            xcat() {
                if [[ $1 == *.gz ]]
                then
                    gunzip -c "$1"
                else
                    cat "$1"
                fi
            }


            d=$( command man -l "$p" 2>/dev/null | \
                     sed -nE '/N(AME|ame)/ {
                                  n; / (—|-) / {p; q;}; N; s/-\n[ ]*/- /; s/\n[ ]*//; p; q; }' )

            cmd=$( sed -E 's/^[ ]*(.*) (—|-) (.*)[ ]*$/\1/' <<< "$d" )
            sd=$(  sed -E 's/^[ ]*(.*) (—|-) (.*)[ ]*$/\3/' <<< "$d" )

            #[[ -z $cmd ]] && echo "ZZZ cmd ZZZ"
            #[[ -z $sd ]] && echo "ZZZ sd ZZZ"

            #[[ -z $sd ]] && { printf "\n\nd='$d'\n\n"; sd=$d; }

            # section number
            bn=$( basename "${p%.gz}" )
            n=${bn##*.}

            # report, adding section number
            printf '%20s - %s\n' "$cmd ($n)" "$sd"
        done
    fi
)

man() {

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

# reformat and open man pages in other apps
if [[ ( -n ${BROWSER:-} || -n $( command -v x-www-browser ) ) &&
      ( -n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-} ) ]]
then
    # Open man pages in the browser in Linux GUI environment
    mano() {
        local tmpfile

        # must pass a file in HOME for garcon-url-handler on ChromeOS
        [[ -d ~/Downloads ]] && tmpfile=$(mktemp -p ~/Downloads "$1".XXXXX.txt)

        MANWIDTH=100 MANPAGER='col -bx' man "$1" > "$tmpfile"
        x-www-browser "$tmpfile"

        # wait for load, then clean up
        sh -c "sleep 5; /bin/rm \"$tmpfile\"" &

        # lacks width setting:
        # groffer --text man:zshoptions | col -bx > zshoptions.txt
    }

    manoh() {
        # NB ChromeOS can't access the /tmp dir
        # - groffer can format text into arbitrary formats, html, pdf, etc.
        GROFF_TMPDIR=~/Downloads  \
            groffer --www --viewer garcon-url-handler  \
                    -P '-s' -P '6' -P -D/home/andrew/Downloads -P -i200  \
                    man:"$1"
    }

elif [[ $(uname -s) == Darwin ]]
then
    # Open man pages in the browser on macOS
    mano() {
        MANWIDTH=100 MANPAGER='col -bx' man "$@" | open -f -a Google\ Chrome
    }
fi

# mman from mandoc
[[ -n $(command -v mman) ]] && {

    true
    #mman() {
    #    mman "$@" | less
    #}
    #
    # mandoc conversion to HTML
    #mandoc -Thtml -Ostyle=style.css .../man1/foo.1.gz > foo.1.html
}


# Open man pages from the web
man-web() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

	    docsh -TD "Read man pages from the web

	    Uses text based browsers links2 or w3m.

	    Usage: ${FUNCNAME[0]} [-u] name

	    Options

          -u: use ubuntu source (default debian)

	    Example

	      ${FUNCNAME[0]} w3m
	    "
	    return 0
    }

    local url="https://manpages.debian.org/jump?q="

    [[ $1 == '-u' ]] && {
        url="http://manpages.ubuntu.com/cgi-bin/search.py?q="
        shift
    }

    local name=$1
    shift

    local cmd cmds=( w3m links2 links elinks )

    for cmd in "${cmds[@]}"
    do
        if command -v "$cmd" >/dev/null
        then
            break
        else
            cmd=''
        fi
    done

    [[ -z ${cmd:-} ]] && err_msg 2 "nothing found from ${cmds[@]}"

    $cmd "${url}${name}"
}
