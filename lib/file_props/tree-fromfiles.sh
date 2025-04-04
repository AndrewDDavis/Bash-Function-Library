# TODO:
# fix tree's report numbers, after filtering with sed

import_func array_match

tree-fromfiles() {

    : "Print tree view of files passed on STDIN

        Usage: tree-fromfiles < <( find -type f -print0 )

        Accepts null-delimited file list, prints using tree.
    "

    # read filenames from stdin, replace newlines with escape codes
    local file_list
    mapfile -d '' file_list

    # bash: ${parameter//pattern/string}
    # - for an array, the substitution is applied to each member in turn, and expanded
    #   to the resulting list
    file_list=( "${file_list[@]//$'\n'/"'\n'"}" )


    # tree command + args
    local tree_cmd
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


    ## sed script to trim the cruft of the --fromfile output
    #
    # - In particular, tree prints the file name as the root directory, which is '.'
    #   when reading from stdin, and that can cause confusion.
    #
    # - It also prints a summary at the end, which can be useful, but is slightly wrong
    #   when it considers the '.' filename to be a dir.

    local tree_filt rs
    tree_filt='
        # trim first and last lines
        1 d; $ d

        # trim the first four chars of most lines
        # - root-dir lines get a newline prepended as well
        # - brackets match space or no-break-sp (c2a0 in hex from hd -X)
        /^.[^  ][^  ]./ { s/^..../\n/; b; }
        /^.[  ][  ]./ { s/^....//; b; }
    '

    "${tree_cmd[@]}" --fromfile <( printf '%s\n' "${file_list[@]}" ) \
        | command sed -E "$tree_filt"

    rs=$( array_max PIPESTATUS )
    return $rs
}
