# TODO:
# - replace sed script with simple shell find/replace

tree-fromfiles() {

    : "Print tree view of files passed on STDIN

        Usage: tree-fromfiles < <( find -type f -print0 )

        This function accepts a null-delimited file list, and prints the corresponding
        file tree using 'tree -aC --filesfirst'. It also improves the output somewhat:

          - Replaces any newlines in filenames with '\\n'.
          - Removes the filename from tree's report (would be e.g. '/dev/fd/62').
          - Corrects tree's output to compensate for the filename removal, by
            deindenting lines, adding newlines before root dirs, and decrementing the
            directory count.
    "

    # read null-delimited filenames from stdin, replace newlines with escape codes
    local file_list
    mapfile -d '' file_list

    # bash: ${parameter//pattern/string}
    # - for an array, the substitution is applied to each member in turn, and expanded
    #   to the resulting list
    file_list=( "${file_list[@]//$'\n'/"'\n'"}" )


    # tree command + args
    local tree_cmd tree_out tree_rpt
    tree_cmd=( "$( builtin type -P tree )" ) \
        || return 9

    # - show files before dirs, for visual clarity
    tree_cmd+=( --filesfirst )

    # - show hidden files, if they are passed on the input
    tree_cmd+=( -a )

    # - use colour, even though the output is going to sed
    # - used to use -F to show classification suffixes like ls -F, but I prefer colour
    [[ -t 1 ]] \
        && (( ${_term_nclrs:-2} >= 8 )) \
        && tree_cmd+=( -C )

    tree_out=$( "${tree_cmd[@]}" --fromfile <( printf '%s\n' "${file_list[@]}" ) ) \
        || return

    ## problems with tree's output:
    #
    # - tree prints the file name as the root directory, which may be e.g. /dev/fd/62,
    #   or '.' when reading from stdin, and that can cause confusion.
    #
    # - it also prints a summary at the end, which can be useful, but is slightly wrong
    #   when it considers the '.' filename to be a dir.

    # may be useful if I decide to use mapfile on tree_out:
    # [[ ${file_list[*]:(-1)} =~ ^([0-9]+)\ (.*)$ ]]


    ## split off tree's report (last line) and edit it to decrement no. of dirs
    [[ $tree_out =~ ^(.+)$'\n'([0-9]+)\ ([^$'\n']+)$ ]]

    tree_out=${BASH_REMATCH[1]}
    tree_rpt="$(( BASH_REMATCH[2] - 1 )) ${BASH_REMATCH[3]}"


    ## sed script to trim the cruft of the --fromfile output
    local tree_filt
    tree_filt='
        # trim first line (filename)
        1 d

        # de-indent the true root-dir
        2 { s/^....//; b; }

        # trim the first four chars of most lines
        # - root-dir lines get a newline prepended as well
        # - brackets match space or no-break-sp (c2a0 in hex from hd -X)
        /^.[^  ][^  ]./ { s/^..../\n/; b; }
        /^.[  ][  ]./ { s/^....//; b; }
    '

    command sed -E "$tree_filt" < <( printf '%s\n' "$tree_out" ) \
        || return

    printf '%s\n' "$tree_rpt"
}
