# notesh
#
# - searches notes for header containing the search string
# - if only 1 file, opens immediately, otherwise presents a choice; could also allow
#   opening multiple
# - opens matching file in less or editor (TUI or GUI: micro, gedit, vs-code, ...)
# - open in less, allows editing in micro
# - open directly in micro, gedit, or vscode (n or r)


# - can use grep, ack, ripgrep, ugrep, etc
# - ideas:
#     + find ~/Notes \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/subdomainA\.example\.com/subdomainB.example.com/g'
#     + grep -rl oldtext . | xargs sed -i 's/oldtext/newtext/g'
#       -Z to grep, -0 to xargs ?
#       --exclude-dir=.svn ?
#     + find /home/www/ -type f -exec \
#       sed -i 's/subdomainA\.example\.com/subdomainB.example.com/g' {} +
#     + menu of items that come back from a search, using a regex with /^#.*<searchterm>/

# TODO: syntax highlighting:
# from [xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja)
# - glow for rendering Markdown in the terminal (bat, pygmentize or highlight can be used as fallback, but glow's output is clearer and therefore glow is recommended)
# - use [glow](https://github.com/charmbracelet/glow) to render markdown in the terminal using a pager

# ugrep globs:
# -g "~/Documents/,*.txt,*.md,*.adoc,*.text"
# or --include-dir='~/Documents/'

# TODO: if matching a heading, search using a plausible glob


notesh() {

    : "Open notes matching a pattern

    Usage: notesh [grep-opts] 'pattern'

    This function searches a directory tree for text files with matches to a pattern,
    and opens the selected file. If more than one file is matched by the pattern, an
    interactive selection screen is presented.

    By default, text files in '~/Documents' are searched, and any symlinks encountered
    are dereferenced and followed. If the working directory is a subdirectory of
    '~/Documents', and '-d' is not used, the working directory is searched.

    The \`ugrep\` command is used to match the pattern, using smart-case matching and
    POSIX ERE syntax by default. If the pattern is simple, containing only alphanumeric
    characters, spaces, dash, and dot, it is expanded to match lines that are mardown
    or asciidoc headings. In this case, a glob is also used to only match files with
    plausible extensions.

    Options

      -p | -e | -v
      : open file using pager (default), editor, or vs-code ('code -n')

      -x 'cmd'
      : open file using custom command

      -d 'dir'
      : search in 'dir/' instead of '~/Documents/'.

      -f
      : match anywhere in the file, rather than only section headings
    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # defaults
    local cmd _f _d

    # dir to search
    _d=~/Documents
    [[ $PWD == ${_d}/* ]] &&
        _d=.

    # command to open file: -p = pager (default), -e = EDITOR, -v = vs-code
    str_split cmd "${PAGER:-less}"

    # args
    local _flag OPTIND=1 OPTARG
    while getopts ':d:fx:pev' _flag
    do
        case $_flag in
            ( d )
                _d=$OPTARG
                [[ $_d != '/' ]] &&
                    _d=${_d%/}
            ;;
            ( f )
                _f=1
            ;;
            ( x )
                str_split -q cmd "$OPTARG"
            ;;
            ( p )
                str_split -q cmd "${PAGER:-less}"
            ;;
            ( e )
                str_split -q cmd "${EDITOR:-vi}"
            ;;
            ( v )
                cmd=( $( builtin type -P code ) -n )
            ;;
            ( \? )
                # arguments for [u]grep should be preserved
                # - OPTIND will have advanced if a lone option was used (like -X) rather than a blob
                _flag=$(( OPTIND-1 ))
                [[ ${!_flag} == -${OPTARG} ]] &&
                    (( OPTIND-- ))
                break
            ;;
            ( : )
                err_msg 2 "missing arg for '-$OPTARG'"
                return
            ;;
        esac
    done
    shift $(( OPTIND-1 ))


    # debug
    # printf >&2 '<%s>\n' "$@"
    # set +x
    # return

    # [u]grep command path and default args
    # - TODO: allow GNU grep as well
    local grep_cmd grep_ptn grep_cmdline
    grep_cmd=$( builtin type -P ugrep ) \
        || return

    # pattern argument required
    # - all else should be grep options
    [[ $# -gt 0 ]] ||
        return 99

    grep_ptn=${!#}

    grep_cmdline=( "$grep_cmd" '-UIjRl0' "${@:1:$(($#-1))}" )


    if [[ ! -v _f ]]
    then
        # for a simple pattern, add regex for heading lines
        # - refer to the  _expand_keyword() function in scw()

        if [[ $grep_ptn != *[![:alpha:][:digit:][:blank:].-]* ]]
        then
            grep_ptn="^(#|=).*${grep_ptn}"

            # match only files with a plausible extension
            # - NB, matching no extension at the same time is tricky: it's possible with
            #   the glob -g '!*.*', but that will exclude all the files with extensions
            #   (--exclude patterns take priority over --include patterns).
            # - you could use e.g. fd, with the '^[^.]+$' regex to create the file list
            # - or do a seperate search with the no-extension glob...
            grep_cmdline+=( -O 'md,adoc,txt,text,markdown' )
        fi
    fi

    grep_cmdline+=( -- "$grep_ptn" "$_d" )

    # capture filenames
    # - for quoted output to shell, use -m1 --format='%h%~'. In a script like this, it
    #   is better to simply use -l.
    # - consider --exclude-dir=.git if there are any git dirs in the search dir
    local fn fns grep_pid grep_rs

    IFS='' mapfile -d '' fns < <(
        set -x
        "${grep_cmdline[@]}"
    )

    # check ugrep return status from subprocess
    grep_pid=$!
    wait $grep_pid || {
        grep_rs=$?
        [[ $grep_rs -eq 1 ]] && return 1
        err_msg $grep_rs "ugrep error"; return
    }

    # select a file
    if [[ ${#fns[@]} -eq 1 ]]
    then
        fn=${fns[0]}

    else
        # modify file paths for display:
        # - replace HOME in root dir with ~
        # - strip root dir from filenames
        # - wrap file paths at a comfortable width, with indentation
        # - bold file basenames and root dir
        local _d_dsp fn_bn fns_dsp=() _bld _rsb _rst

        _bld=$'\e[1m'
        _rsb=$'\e[22m'
        _rst=$'\e[0m'

        _d_dsp=${_bld}${_d/#${HOME}/\~}/${_rsb}

        for fn in "${fns[@]}"
        do
            fn=$( fmt -sw88 <<< "${fn#${_d}/}" )
            fn=$( sed '1 {p;d;}; s/^/    /' <<< "$fn" )
            fn_bn=${fn##*/}
            fn=${fn%${fn_bn}}${_bld}${fn_bn}${_rsb}

            fns_dsp+=( "$fn" )
        done

        # could use fzf, e.g.
        # fn=$( fzf <<< $( printf '%s\n' "${fns[@]}" ) )
        # -m for multi

        # TODO:
        # - present candidate files grouped by subdir of ~/Documents/, or format like:
        #   1) filename from this/long/path

        # or the Bash builtin 'select'
        printf '\n%s\n\n' "Matching files from '${_d_dsp}':"

        PS3=$'\n'"Select a file to open, by number (^D to cancel): "

        # select:
        # - Ctrl-D prevents a selection and returns 1
        # - fn is set to null for an invalid response
        select fn in "${fns_dsp[@]}"
        do break
        done || return

        [[ -n $fn ]] || return

        # recover the proper filename
        fn=${fn/${_bld}/}
        fn=${fn/${_rsb}/}
        fn=${fn//$'\n    '/ }
        fn=${_d}/${fn}
    fi

    printf '\n%s\n\n' "Opening file with ${cmd[0]}: '$fn'"

    (
        set -x
        "${cmd[@]}" "$fn"
    )


    # testing grep + find
    # - about the same, but more complicated; might be faster for larger number of files
    #printf 'find + grep vvv\n\n'
    #time find ~/Sync/Notes/ \( -type d -name .git -prune \) -o -type f -name '*.md.txt' -exec  \
    #    egrep -li "^#.*$@" {} +

    # sed is unwieldy for this task
    # printf '\n\nsed vvv\n\n'
    # time find ~/Sync/Notes/ \( -type d -name .git -prune \) -o -type f -name '*.md.txt' -exec  \
    #     bash -c '_str=$0
    #              [[ -n $(sed -nE "/^#.*${_str}/I p" "$@") ]] && echo "$@"
    #             ' "$1" '{}' \;
    #
    #printf '\n\n'
}
