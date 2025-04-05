# TODO:
# - I think this file is obscelete

# alias for discoverability
# alias tree-fd='fd-tree'

import_func fd-wrapper

fd-tree_old() {

    : "Match files with fd, display as tree

        Usage: fd-tree [fd-opts] [fd-pattern]

        All arguments are passed to \`fd\`, which generates a list of matching
        filenames. The list displayed in a tree-like format by filtering it using the
        \`tree\` command and a \`sed\` filter.

        This function calls the fd-wrapper function, if present. Refer to those docs
        for relevant options and usage details. Otherwise, calls fd with the
        --no-ignore-vcs flag.
	"

	[[ $# -eq 1  && $1 == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    # prefer fd-wrapper function, otherwise fd or fdfind
    local fd_cmd
    if [[ $( type -t fd-wrapper ) == function ]]
    then
        fd_cmd=( fd-wrapper )
    else
        fd_cmd=( "$( builtin type -P fd )" ) \
            || fd_cmd=( "$( builtin type -P fdfind )" ) \
                || return 9

        fd_cmd+=( --no-ignore-vcs )
    fi

    # show hidden files
    # - used to use -F to show classification suffixes like ls -F, but I prefer colour
    local tree_args=( '-a' )

    # use colour, even though the output is going to sed
    [[ -t 1 ]] \
        && (( ${_term_nclrs:-2} >= 8 )) \
        && tree_args+=( '-C' )

    ## sed script to trim the cruft of the --fromfile output
    #
    # - In particular, tree prints the file name as the root directory, which is '.'
    #   when reading from stdin, and that can cause confusion.
    #
    # - It also prints a summary at the end, which can be useful, but is slightly wrong
    #   when it considers the '.' filename to be a dir.

    local tree_filt
    tree_filt='
        # trim first and last lines
        1 d; $ d

        # trim the first four chars of most lines
        # - root-dir lines get a newline prepended as well
        # - brackets match space or no-break-sp (c2a0 in hex from hd -X)
        /^.[^  ][^  ]./ { s/^..../\n/; b; }
        /^.[  ][  ]./ { s/^....//; b; }
    '

    "$fd_cmd" "$@" \
        | command tree "${tree_args[@]}" --fromfile . \
        | command sed -E "$tree_filt"

    # PIPESTATUS? (TODO)
}
