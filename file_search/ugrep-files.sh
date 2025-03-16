# TODO:
#
# - make a --in-headings option, to be called from notesh() for a pattern like '##.*flatpak'
# - make a --shellcode option, to search the shell code repository in ~/Projects, using
#   a line like:
#   ugrep -RIUY --sort --exclude='*_history_*' --heading -F '_run_vrb'
#
# - testing in ~/Scratch/grepfiles
#
#   testing matrix:
#   'ugrep-files -tTi attachment' from '~/Documents/Health...' dir
#   'ugrep-files -i truecrypt' from '~/Documents/Computing...' dir

alias grep-files='ugrep-files'
alias egrep-files='ugrep-files'

ugrep-files() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Search for files by their content

        Usage: ugrep-files [opts] <pattern> [path-root ...]

        The pattern is interpreted as extended regex (ERE). If no path-roots are given,
        the working directory is searched. This function calls \`ugrep\` with the
        options '-RljIUY' and '--sort', described below. Since \`ugrep\` includes most
        of the existing and planned functionality of the old \`grep-files\` function
        that called GNU \`grep\`, this function is mostly a wrapper for \`ugrep\` that
        passes all arguments through, excepting those listed below. The defaults can be negated by using the long
        option form '--no-<option>', e.g. '--no-ignore-case'.

          --no-l
          : this option negates -l, and is easier to use than '--no-files-with-matches',
            but it also enables '--pretty'.

          --verbose
          : print the ugrep command as it is run

        Multiple patterns may be supplied to any grep tools, including \`ugrep\`, using a
        command line syntax like \`-e 'A' -e 'B'\`. These are interpreted with a logical
        OR condition, as if the expression had been \`'A|B'\`. When searching for files
        that match multiple patterns on the same line (logical AND), one can use a
        pattern like 'A.*B|B.*A'. When the matches may be on different lines,
        traditional greps and ripgrep require multiple calls in a pipeline. The \`git
        grep\` tool introduced the options '--and' and '--not' to facilitate this, and
        those are also supported by \`ugrep\`. However, \`ugrep\` also supports a
        simpler boolean logic syntax using '-%' and '-%%', as described below.

        Output formatting options in \`ugrep\` are numerous, including '--format',
        '--pager', options for CSV, JSON, or XML, and the catch-all
        '--pretty', which invokes '--color', '--heading', '-n', '--sort', '--tree' and
        '-T'. Other features beyond traditional grep include config files, launching an
        interactive query interface with '-Q', matching file types with '-t', '-M', and
        '-O', searching compressed files with '-z', other file types with '--filter',
        replacement of match text with '--replace', fuzzy matching with '-Z', etc. The
        documentation for \`ugrep\` is also excellent, both at ugrep.com, and inline
        using e.g. \`ugrep --help regex\`.

        Option '--index' causes ugrep to use any index files encountered in the
        directory tree. The index files are created by \`ugrep-indexer\`, one per
        indexed directory, and are named '._UG#_Store'. This generally speeds up
        recursive searches, especially for compressed files. Ugrep's indexed-based
        search is safe in that it never skips new or updated files that may now match.
        Refer to the 'ugrep-indexer' manpage and my notes in 'File Search' for details.

        Notable \`ugrep\` options

          -r (--recursive), -R (--dereference-recursive), -S (--dereference-files)
          : search recursively within files and directories. '-R' will follow symlinks
            in the sub-paths. '-S' will follow symlinks to files, but not directories.

          -l (--files-with-matches)
          : print only the list of filenames, without matching lines

          -c (--count)
          : print the count of matching lines for each filename, rather than the
            text of the lines. Prints the count of total matches with '-o', and omits
            files with zero matches with '-m 1,'.

          -i (--ignore-case), -j (--smart-case)
          : case insensitive search. '-j' is case-insensitive unless the pattern has an
            upper case ASCII letter.

          -w (--word-regexp)
          : match the pattern as a word, surrounded by non-word characters. Words are
            formed from letters, digits, and underscores.

          -x (--line-regexp)
          : match whole lines only (i.e. pattern is surrounded by '^' and '$')

          -I (--ignore-binary)
          : ignore binary files. Once grep determines that a file contains binary rather
            than text data (e.g. when a NUL byte is encountered), the rest of the file
            is skipped as if it contains no matches. By default, grep reports matches in
            binary files with a message to STDERR, but suppresses output.

          -. (--hidden)
          : Match hidden files, which are otherwise ignored by default.

          -U (--ascii)
          : disable Unicode matching. The pattern matches bytes, as in GNU grep, rather
            than Unicode characters.

          -Y (--empty)
          : allow empty-matching patterns like 'x*' to pass through unchanged and match
            all lines (or files) as other grep variants would. By default, ugrep would
            change such a pattern to 'x+', in an effort to guess what you meant.

          -% (--bool), -%% (--bool --files)
          : boolean matching of lines or whole files. The AND operator is represented by
            space, OR by '|', and NOT by '-', and grouping occurs with '(...)'. E.g.
            'A -B' is the same as 'A AND NOT B'. The options '--and', '--andnot', and
            '--not' are also available, so that the above could be written
            '-e A --andnot B'.

          -g GLOB, --(ex|in)clude[-dir]=GLOB, --(ex|in)clude-from=FILE, --ignore-files[=...]
          : include or exclude files to search using glob patterns. The '--exclude' form
            is the same as \"-g '!GLOB'\". Globs match only files, except for globs that
            end in '/', which match only directories as in the --include-dir form. Globs
            match the whole path if they include '/', otherwise only the basename. The
            '--include-from' form specifies a file of globs to use. The '--ignore-files'
            option causes \`ugrep\` to respect ignores found in a standard file in the
            filesystem, by default '.gitignore'. All globs use gitignore syntax, which
            is a bit quirky, refer to \`ugrep --help globs\`.

          --sort
          : sort output, rather than presenting matches as they are found. Without an
            argument, sorts by name, but can also sort by times, size, or best during
            fuzzy matches.

          -^ (--tree)
          : display file matches as tree when using -c, -l, or -L.

          --index
          : speed up recursive searches by using index files created by 'ugrep-indexer'
        "
        docsh -TD
        return
    }

    # clean up
    trap '
        unset -f _run_grep
        trap - return
    ' RETURN

    # defaults and args
    local _i _v=1
    local ug_opts=( '-RljIUY' '--sort' )
    local ug_args=( "$@" )
    shift $#

    # check for recognized options
    _i=$( array_match -n -- ug_args '--no-l' ) && {

        #ug_opts+=( --no-files-with-matches --pretty )

        # work around bug "invalid option --no-files-with-matches"
        ug_opts+=( --heading -n )
        ug_opts[0]=${ug_opts[0]/l/}

        unset ug_args[$_i]
    }

    _i=$( array_match -n -- ug_args '--verbose' ) && {

        (( _v++ ))
        unset ug_args[$_i]
    }

    _i=$( array_match -np -- ug_args '^-[^-]*i[^-]*' ) && {

        # work around behaviour of -j overriding -i
        # - split key & value from _i
        array_irepl ug_args "${_i%%:*}" '--no-smart-case' "${_i#*:}"
    }

    # local flag OPTARG OPTIND=1

    # while getopts '' flag
    # do
    #     case $flag in
    #         ( \? )
    #             # other short option flags
    #             ug_opts+=( -$OPTARG )
    #         ;;
    #         ( ':' )
    #             err_msg 2 "-$OPTARG requires argument"
    #             return
    #         ;;
    #     esac
    # done
    # shift $(( OPTIND - 1 ))


    (
        [[ $_v -gt 1 ]] && set -x
        ugrep "${ug_opts[@]}" "${ug_args[@]}"
    )
}


### OLD CODE

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
#         if (( ${_term_nclrs:-2} >= 8 ))
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
#             str_to_words -q ls_cmd "${BASH_ALIASES[ls]}"

#             # env is needed for aliases of the form 'KEY=val cmd'
#             [[ ${ls_cmd[0]} == *=* ]] && ls_cmd=( env "${ls_cmd[@]}" )
#         fi

#         # NB -Q puts the file names in double-quotes, and escapes non-printables
#         "${ls_cmd[@]}" -1dQ -- "${fns[@]}"
#     fi
# }
