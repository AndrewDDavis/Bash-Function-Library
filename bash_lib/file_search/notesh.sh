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

# TODO:
# - if two args are passed for pattern, maybe treat it like -%% 'word1 word2'?
# - otherwise, how to pass -%% ...

# - create project aliases, like --bread, or --project=bread

# dependencies
import_func run_vrb vrb_msg \
    || return

notesh() {

    : "Open notes matching a pattern

    Usage: notesh [options] [--] [grep-options] 'pattern'

    Search for and open a notes file with content that matches a pattern. If more than
    one file is matched by the pattern, an interactive selection screen is presented.

    By default, text files in '~/Documents' are searched, and any symlinks encountered
    are dereferenced and followed. If the working directory is a subdirectory of
    '~/Documents', and '-d' is not used, the working directory is searched.

    The \`ugrep\` command is used to match the pattern, using smart-case matching and
    POSIX ERE syntax by default. If the pattern is simple, containing only alphanumeric
    characters, spaces, dash, and dot, it is expanded to match lines that are mardown
    or asciidoc headings. In this case, a glob is also used to only match files with
    plausible extensions.

    Options

      -d 'dir'
      : search in 'dir/' instead of '~/Documents/'.

      -f
      : match anywhere in the file, rather than only section headings

      -o <p|e|s|v>
      : open file using PAGER (default), EDITOR, sublime text ('subl -n'), or
        vs-code ('code -n')

      -x 'cmd ...'
      : open file using custom command; the argument will be split into words.
    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] \
        && { docsh -TD; return; }

    # cleanup routine
    trap '
        unset -f _parse_opts _def_grep_cmd _match_fns _select_fn
        trap - return
    ' RETURN

    _parse_opts() {

        # root of search tree
        doc_root=$HOME/Documents
        [[ $PWD == ${doc_root}/* ]] \
            && doc_root=.

        # default opener is PAGER
        str_to_words opener "${PAGER:-less}"

        # args
        local flag OPTIND=1 OPTARG
        while getopts ':fd:o:x:' flag
        do
            case $flag in
                ( d )
                    doc_root=$OPTARG
                    [[ $doc_root != '/' ]] \
                        && doc_root=${doc_root%/}
                ;;
                ( f )
                    full_match=1
                ;;
                ( o )
                    # define opener from first char of OPTARG
                    case ${OPTARG:0:1} in
                        ( p ) str_to_words -q opener "${PAGER:-less}" ;;
                        ( e ) str_to_words -q opener "${EDITOR:-vi}" ;;
                        ( s ) opener=( "$( builtin type -P subl )" -n ) ;;
                        ( v ) opener=( "$( builtin type -P code )" -n ) ;;
                    esac
                ;;
                ( x )
                    str_to_words -q opener "$OPTARG"
                ;;
                ( \? )
                    # likely [u]grep option: preserve it and stop processing options
                    # - OPTIND will have advanced if a lone option was used (like -X) rather than a blob
                    flag=$(( OPTIND-1 ))
                    [[ ${!flag} == -${OPTARG} ]] &&
                        (( OPTIND-- ))
                    break
                ;;
                ( : )
                    err_msg 2 "missing argument for '$OPTARG'"
                    return
                ;;
            esac
        done
        n=$(( OPTIND-1 ))
    }

    _def_grep_cmd() {

        # - TODO: allow GNU grep as well
        grep_cmdln=( "$( builtin type -P ugrep )" ) \
            || return 9

        grep_cmdln+=( '-UIjRl0' )

        # pattern argument required
        [[ $# -gt 0 ]] \
            || return 3

        # - all else should be grep options
        grep_ptn=${!#}
        grep_cmdln+=( "${@:1:$(($#-1))}" )
        shift $#

        if  [[ ! -v full_match
            && $grep_ptn != *[![:alpha:][:digit:][:blank:].-]* ]]
        then
            # for a simple pattern, add regex for heading lines
            # - refer to the  _expand_keyword() function in scw()
            grep_ptn="^(#|=).*${grep_ptn}"

            # match only files with a plausible extension
            # - NB, matching no extension at the same time is tricky: it's possible with
            #   the glob -g '!*.*', but that will exclude all the files with extensions
            #   (--exclude patterns take priority over --include patterns).
            # - you could use e.g. fd, with the '^[^.]+$' regex to create the file list
            # - or do a seperate search with the no-extension glob...
            grep_cmdln+=( -O 'md,adoc,txt,text,markdown' )
        fi

        grep_cmdln+=( -- "$grep_ptn" "$doc_root" )
    }

    _match_fns() {

        # match using grep
        # capture filenames
        # - for quoted output to shell, use -m1 --format='%h%~'. In a script like this,
        #   it is better to simply use -l.
        # - consider --exclude-dir=.git if there are any git dirs in the search dir
        local grep_rs #grep_pid

        mapfile -d '' fns < \
            <(
            set -x
            "${grep_cmdln[@]}"
        )

        # check ugrep return status from subprocess
        # grep_pid=$!
        # wait $grep_pid \
        wait $! \
            || {
            grep_rs=$?
            [[ $grep_rs -eq 1 ]] \
                && return 1 \
                || { err_msg $grep_rs "grep command call error"; return; }
        }

        # tested grep + find for matching
        # - about the same, but more complicated
        # - might be faster for larger number of files
        #   printf 'find + grep vvv\n\n'
        #   time find ~/Sync/Notes/ \( -type d -name .git -prune \) -o -type f -name '*.md.txt' \
        #       -exec egrep -li "^#.*$@" {} +
        # - NB, sed is unwieldy for this task
    }

    # _sort_fns() {

        # sort fns

        # TODO
        # - present candidate files grouped by subdir of ~/Documents/, or format like:
        #   1) filename from this/long/path
    # }

    _select_fn() {

        # select a file from the matches
        if (( ${#fns[@]} == 1 ))
        then
            fn=${fns[0]}
            vrb_msg 1 "Matched $fn"
            # vrb_msg 1 '' "Matched Opening file with ${opener[0]}: '$fn'"
            return
        fi

        ## improve file path strings for display:
        # - replace HOME in root dir with ~
        # - strip root dir from filenames
        # - wrap file paths at a comfortable width, and indent following lines
        # - bold file basenames and root dir
        local _bld _rsb _rst
        _bld=$'\e[1m'
        _rsb=$'\e[22m'
        _rst=$'\e[0m'

        local dr_dsp=${_bld}${doc_root/#"$HOME"/\~}/${_rsb}
        printf >&2 '%s\n' '' "Matching files from '${dr_dsp}':" ''

        local fn_bn fns_dsp=()
        for fn in "${fns[@]}"
        do
            fn=$( command fmt -sw88 <<< "${fn#"${doc_root}"/}" )
            fn="${fn//$'\n'/&    }"
            # fn=$( command sed '1 {p;d;}; s/^/    /' <<< "$fn" )
            fn_bn=${fn##*/}
            fn=${fn%"$fn_bn"}${_bld}${fn_bn}${_rsb}

            fns_dsp+=( "$fn" )
        done

        # Call the Bash builtin 'select'
        # - Ctrl-D prevents a selection and returns 1
        # - fn is set to null when response is invalid
        PS3=$'\n'"Select a file to open, by number (^D to cancel): "

        select fn in "${fns_dsp[@]}"
        do
            [[ -z $fn ]] || break

        done || return

        # recover the un-decorated filename from the selection
        fn=${fns[REPLY-1]}

        # TODO:
        #
        # - consider using fzf, e.g.
        #   fn=$( fzf <<< $( printf '%s\n' "${fns[@]}" ) )
        #   -m for multi
    }


    # set defaults and parse options
    local doc_root opener full_match _verb=2
    local -i n
    _parse_opts "$@" || return
    shift $n

    # [u]grep command path and default args
    local grep_cmdln grep_ptn
    _def_grep_cmd "$@" || return
    shift $#

    # match files and select one to open
    local fn fns
    _match_fns  || return
    # _sort_fns   || return
    _select_fn  || return

    run_vrb "${opener[@]}" "$fn"
}
