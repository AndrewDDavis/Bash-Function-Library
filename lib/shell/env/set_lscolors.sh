set_lscolors() {

    [[ $# -gt 0  && $1 == @(-h|--help) ]] && {

        : "Customize colours used by GNU ls, tree, and others

            Usage

            set_lscolors [options]

            -c : Check whether dircolors default database has been updated since the
                default config file was last written to disk, and notify if it has. It
                is recommended to run this occasionally, particularly after an update
                to the coreutils package.

            -p : Print the default settings in colour, to show what the colours look
                like in your shell.

            On the initial run, set_lscolors creates config files in
            '~/.config/lscolors/' (or in XDG_CONFIG_HOME if set). An empty file called
            \`dircolors.custom\` will be created, in which custom colour settings can
            be added. The default dircolors database is written as \`dircolours.defaults\`,
            using the \`dircolors -p\` command, and includes helpful comments describing
            the meaning of the lines. The \`dir_colors\` manpage is also useful. Note
            that glob patterns may be used in TERM or COLORTERM entries, but not for
            matching file extensions.

            To customize the configuration, copy relevant lines from dircolors.defaults into
            dircolors.custom and modify them. By leaving the defaults file unchanged, we allow
            for the future detection and inclusion of changes to the dircolors defaults. After
            making changes in dircolors.custom, run set_lscolors to modify LS_COLORS in
            the current shell session and enact the changes. To make the changes permanent, add
            the function call to your '~/.bashrc', '~/.zshrc', or the relevant startup file for
            your shell.

            The most likely lines of interest are those for the basic file types, such as the
            lines starting with DIR, LINK, or EXEC or the lines for specific file extensions,
            such as .jpg, .mp3, or .bak.

            Background

            The LS_COLORS environment variable defines the colours used in the output of GNU's
            ls command. This sets the colours of file-names based on file type, extension, or
            permissions. Typically, it is set in a shell init file using the output of the
            dircolors command from the GNU coreutils package. E.g., using
            \`eval \$(dircolors -b)\`. The command outputs a series of colour strings to match
            against file extensions, separated by ':', and includes the syntax to export the
            LS_COLORS variable. Without a file argument, dircolors emits the colors from a
            precompiled database. For more info, see \`man\` pages for 'dir_colors',
            'dircolors', and 'ls'. Note the comments in 'dir_colors' indicating that GNU
            dircolors ignores any /etc/DIR_COLORS or ~/.dir_colors files, and several options.

            While it may seem like a bad idea to run dircolors every time you start a new shell,
            in my testing it took < 7 ms to run.

            dircolors file format
            - Important lines start with an uppercase word or a pattern,
                then a space and another word.
            - patterns start with . or *
            - there are no tabs or double spaces
            - comments start with #
            - some (comment) lines have leading blanks

            256-color sequences
            - https://user-images.githubusercontent.com/1482942/93023823-46a6ba80-f5e1-11ea-9ea3-6a3c757704f4.png
        "
        docsh -TD
        return
    }

    # TODO
    # - check whether custom file has been updated before running full merge
    # - remove write permission on defaults file and combined file
    # - consider setting up LSCOLORS for BSD ls
    # - consider GREP_COLORS
    # - make some ChromeOS terminal colours more like vscode ones, especially cyan
    # - add an 'unset' or 'none' option, to delete a setting
    # - also consider NNN colours, see man page, NNN_COLORS and NNN_FCOLORS
    # - use getopts for options
    # - there are good ideas for how to structure a function like this in [this repo][1]
    #   such as using the env var 'export COLORS_DEFINED="yes"'
    #   [1]: https://github.com/Sitwon/bash_patterns/blob/master/colors.sh

    trap '
        trap-err $?
        return
    ' ERR

    trap '
        trap - err return
        unset -f _strip_dcfile
    ' RETURN

    [[ -n $( command -v dircolors ) ]] ||
        err_msg 2 "dircolors not found"

    # defaults and parse args
    local _chk_defs _prnt_defs

    local flag OPTARG OPTIND=1
    while getopts "cp" flag
    do
        case $flag in
            ( c ) _chk_defs=1 ;;
            ( p ) _prnt_defs=1 ;;
            ( * ) return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # config directory
    local _lscdir=${XDG_CONFIG_HOME:-~/.config}/lscolors

    [[ ! -e $_lscdir ]] && {

        /bin/mkdir -p "$_lscdir"
    }

    # defaults file
    if [[ ! -e "$_lscdir"/dircolors.defaults ]]
    then
        dircolors -p > "$_lscdir"/dircolors.defaults

    elif [[ -n ${_chk_defs-} ]]
    then
        # check current defaults against existing file
        local _chk_fn
        _chk_fn=$( mktemp -t lscolors_tmp.XXXXX )

        dircolors -p > "$_chk_fn"

        if diff -q "$_chk_fn" "$_lscdir"/dircolors.defaults &> /dev/null
        then
            printf '%s\n' "No changes detected in dircolors defaults."
            /bin/rm "$_chk_fn"
        else
            printf '%s\n' \
                "Change detected in dircolors defaults."  \
                "New defaults written to \"$_lscdir/dircolors.defaults.new\"." \
                "View the changes using e.g.: diff -u --color $_lscdir/dircolors.defaults{,.new}"  \
                "Start using the new defaults using: mv -f $_lscdir/dircolors.defaults{.new,}"

            /bin/mv -f "$_chk_fn" "$_lscdir"/dircolors.defaults.new
        fi
    fi

    [[ -n ${_prnt_defs-} ]] && {

        dircolors --print-ls-colors "$_lscdir"/dircolors.defaults
        return 0
    }

    # merge defaults and custom
    _strip_dcfile() {

        # Reads from passed filename, edits lines as noted below, writes to stdout.
        sed -E '/^[ \t]*$/ d        # delete empty or blank lines
                /^[ \t]*#/ d        # delete comment lines
                s/^[ \t]+//         # strip leading blanks
                s/[ \t]+$//         # strip trailing blanks
                s/[ \t]+#.*$//      # strip trailing comments
                s/[ \t][ \t]+/ /    # squash multiple blanks into 1 space
               ' "$1"
    }

    if [[ ! -s "$_lscdir"/dircolors.custom ]]
    then
        # no custom settings, nothing to merge
        [[ ! -e "$_lscdir"/dircolors.custom ]] &&
            touch "$_lscdir"/dircolors.custom

        _strip_dcfile "$_lscdir"/dircolors.defaults > "$_lscdir"/dircolors.combined

    else
        # (elif) check whether custom file has been updated since last time
        # combo file was created
        # ...

        # (else)
        # merge files, ensuring custom has priority
        # strategy:
        #   - read defaults lines into array in memory
        #   - loop line-by-line through custom file
        #   - get key from custom line
        #   - if custom key matches defaults entry, replace line
        #   - else, add custom line to end of defaults array
        #   - write out customized array to disk


        # 1. Read defaults lines into memory as array(s)
        # - this will form the basis of the "combined" database file
        # - uses process substitution to create a fifo, then reads it in to stdin
        local -a keys clrs
        local _key _clr

        while read -r _key _clr
        do
            keys+=("$_key")
            clrs+=("$_clr")

        done < <( _strip_dcfile "$_lscdir"/dircolors.defaults )

        # read -r -d '' -a def_lns < <( _strip_dcfile "$_lscdir"/dircolors.defaults )

        # Condsidered an associative array, however the retrieval is random,
        # and I wanted to be able to write it out in the original order.
        #local -A dc_defs
        #local key clr
        #while read -r key clr
        #do
        #    dc_defs[$key]=$clr
        #done < <( _strip_dcfile "$_lscdir"/dircolors.defaults )


        # 2. Loop line-by-line through custom file
        # - edit the values from defaults, or add new lines
        # - the custom file is stripped of blank lines, comments, and leading
        #   whitespace on reading
        local _n # _key cst_line

        while read -r _key _clr
        do
            # get key from custom line
            # _key=$(cut -d ' ' -f 1 - <<< "$cst_line")
            # - file format should be consistent enough for cut now
            # _key=$(sed -E 's/^[ \t]*([^ \t]+) .*$/\1/' <<< "$cst_line")


            if _n=$(printf '%s\n' "${keys[@]}" | fgrep -xn "$_key")
            then
                # custom key matches defaults entry, so replace value
                _n=${_n%:${_key}}
                _n=$((_n - 1))    # 0-based index

                clrs[$_n]=$_clr
            else
                # no matching entry from defaults, so add
                keys+=("$_key")
                clrs+=("$_clr")
            fi

            # or, could just use grep and sed directly on the file...
            # sed cmd to overwrite line in .combined file
            # or just add it at the end if it's not already there
            #sed -E "/^$prefix/" #...
        done < <( _strip_dcfile "$_lscdir"/dircolors.custom )


        # write out combined database
        #printf '%s %s\n' "${keys[@]}" "${clrs[@]}" > "$_lscdir"/dircolors.combined
        > "$_lscdir"/dircolors.combined

        for _n in ${!keys[@]}
        do
            printf '%s %s\n' "${keys[_n]}" "${clrs[_n]}" >> "$_lscdir"/dircolors.combined
        done
    fi

    # Set LS_COLORS and export it in the shell
    # - extract the string from dircolors cmd
    declare -gx LS_COLORS
    LS_COLORS=$( dircolors -b "$_lscdir"/dircolors.combined |
                     sed -E "s/^LS_COLORS='(.*):';\$/\1/; q" )
}
