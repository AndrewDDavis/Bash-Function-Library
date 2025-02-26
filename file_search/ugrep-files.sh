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


ugrep-files() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Search files by content, using ugrep

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
