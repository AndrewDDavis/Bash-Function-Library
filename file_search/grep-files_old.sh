alias grep-files='echo "use ugrep-files"'


# the code below was developed before I started using ugrep, and is superceded
# by ugrep-files. the discussion on ripgrep and git grep was moved to the 'File Search'
# notes file.


# TODO:
#
# - make a --headings option, which does a search like:
#   grep -Eir '##.*flatpak'
#
# - make a --context option or something, which shows matching lines from the files;
#   this is similar to just running 'grep -r' without '-l', but it would collect the
#   entries from each file, maybe with separators kind of like diff.
#   e.g. in the ~/Documents/Computing dir, running 'grep-files --context udisk' should
#   return two file names with multiple lines of context
#
# - testing in ~/Scratch/grepfiles
#
#   testing matrix:
#   'grep-files -tTi attachment' from '~/Documents/Health...' dir
#   'grep-files -i truecrypt' from '~/Documents/Computing...' dir



# alias egrep-files="grep-files -E"

# grep-files() {

#     [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

#         : "Search file contents, display matching files as list or tree

#         Usage: grep-files [opts] <pattern> [path-root ...]

#         The pattern is interpreted as extended regex (ERE). If no path-roots are given,
#         the working directory is searched. Most other arguments are passed directly to
#         \`grep\`, with the exception of the options listed below. To pass an option to
#         \`grep\` that has the same name as one of \`grep-files\`'s options, include '--'
#         as an argument before the option.

#         By default, \`grep-files\` passes the '-l', '-R', and '-I' options to \`grep\`
#         (described below). It calls the 'greps' shell function to achieve smart-case
#         search functionality (i.e. case-insensitive search unless a non-escaped
#         uppercase character appears in the pattern). This behaviour can be modified with
#         '-i' or '-j' (refer to 'greps --help').

#         Options interpreted by \`grep-files\`

#           -a <regex>
#           : add search for pattern using AND in file

#           -J
#           : treat binary files as grep does by default (see -I below)

#           -t
#           : search only text files (extensions .txt, .md, .adoc, .rtf, .tex, etc.)
#             implies '-J'.

#           -T
#           : display file matches as tree


#         Notable \`grep\` options

#           -r, -R
#           : search recursively within files and directories. '-R' will follow symlinks
#             in the sub-paths.

#           -l
#           : print only the list of filenames, without matching lines

#           -i
#           : case insensitive search

#           -w
#           : match words only

#           -x
#           : match whole lines only

#           -I
#           : ignore binary files completely. Once grep determines that a file contains
#             binary rather than text data (e.g. when a NUL byte is encountered), the rest
#             of the file is skipped as if it contains no matches. By default, grep
#             reports matches in binary files with a message to STDERR, but suppresses
#             output. The default behaviour can be restored using '-J', which passes
#             '--binary-files=binary' to grep.

#           --exclude=GLOB, --include=GLOB
#           : skip files whose base name matches GLOB, or search only those files


#         Searching for multiple patterns:

#         - To search for files that match any of several patterns (logical OR), it's
#           trivial to use the pattern \`'A|B'\`, which is also the way grep interprets
#           \`-e 'A' -e 'B'\`.

#         - When searching for files that match multiple patterns on the same line, it's
#           straightforward to use a pattern like 'A.*B|B.*A'. However, when the matches
#           may be on different lines, multiple calls to grep must be chained together.
#           This is the use case for the '-a' option to grep-files described above.
#         "
#         docsh -TD
#         return
#     }

#     # clean up
#     trap '
#         unset -f _run_grep
#         trap - return
#     ' RETURN

#     # defaults and args
#     local and_pats=() grep_opts=( '-RlI' )
#     local _t _v=1 _tree=''
#     local flag OPTARG OPTIND=1

#     while getopts ':a:JtT' flag
#     do
#         case $flag in
#             ( a )
#                 and_pats+=( "$OPTARG" )
#             ;;
#             ( J )
#                 grep_opts+=( "--binary-files=binary" )
#             ;;
#             ( t )
#                 # text(-ish) files only
#                 grep_opts+=( "--binary-files=binary" )
#                 for _t in txt md text adoc ad asc asciidoc rtf tex
#                 do
#                     grep_opts+=( --include="*.$_t" )
#                 done
#             ;;
#             ( T )
#                 _tree=1
#             ;;
#             ( \? )
#                 # other short option flags
#                 grep_opts+=( -$OPTARG )
#             ;;
#             ( ??* )
#                 # other long option flags
#                 grep_opts+=( "--$flag" )
#             ;;
#             ( ':' )
#                 err_msg 2 "-$OPTARG requires argument"
#                 return
#             ;;
#         esac
#     done
#     shift $(( OPTIND - 1 ))


#     _run_grep() (
#         [[ $_v -gt 0 ]] && set -x
#         greps "${grep_opts[@]}" "$@"
#     )

#     # find matching files with grep
#     # -t : remove trailing delim from each line
#     # - nullify IFS to preserve leading and trailing whitespace in the fields
#     # - not using process substitution '<(...)' to retain the return status
#     local grep_out fns=()

#     grep_out=$( _run_grep "$@" )
#     readarray -t fns <<< "$grep_out"

#     # Filter the results using AND patterns

#     # TODO: the number of args before the final pattern can vary here!
#     #       maybe need to process the args to find the pattern like egreps

#     local _pat
#     for _pat in "${and_pats[@]}"
#     do
#         readarray -t fns < <( _run_grep "${@:1:$#-2}" "$_pat" "${fns[@]}" )
#     done


#     # Print results, if any, as list or tree
#     if [[ -z "${fns[@]}" ]]
#     then
#         #printf >&2 '%s\n' "No matches."
#         return 1  # consistent with regular grep -q

#     elif [[ -n ${_tree:-} ]]
#     then
#         local -a _tree_args=()

#         # test for colour support
#         if [[ ${_term_n_colors:-2} -ge 8 ]]
#         then
#             _tree_args+=( "-C" )
#         fi

#         # sed script to trim the cruft of the --fromfile syntax
#         local _sed_script
#         _sed_script='# trim first and last lines
#                      1 d; $ d

#                      # trim the first four chars of most lines
#                      # - root-dir lines get a newline prepended as well
#                      # - brackets match space or no-break-sp (c2a0 in hex from hd -X)
#                      /^.[^  ][^  ]./ { s/^..../\n/; b; }
#                      /^.[  ][  ]./ { s/^....//; b; }
#                     '

#         tree -aFC --fromfile . <<< $( printf '%s\n' "${fns[@]}" ) |
#             sed -E "$_sed_script"

#     else
#         # Ensure any alias for 'ls' gets used, e.g. for 'ls --color'
#         # - this is the calling shell's alias
#         local ls_cmd=( ls )

#         if alias ls &>/dev/null
#         then
#             # word splitting that respects quotes
#             str_split -q ls_cmd "${BASH_ALIASES[ls]}"

#             # env is needed for aliases of the form 'KEY=val cmd'
#             [[ ${ls_cmd[0]} == *=* ]] && ls_cmd=( env "${ls_cmd[@]}" )
#         fi

#         # NB -Q puts the file names in double-quotes, and escapes non-printables
#         "${ls_cmd[@]}" -1dQ -- "${fns[@]}"
#     fi
# }
