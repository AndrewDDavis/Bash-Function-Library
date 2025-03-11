fd-tree() {

    : "Match files with fd, display as tree

        Usage: fd-tree [args for fd]

        All arguments are passed to fd. Refer to my fd wrapper script for usage details.
	"

	[[ $# -eq 0  || $1 == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    # from the old grep-files code
    local tree_args=( '-aF' )

    # use colour, even though the output is going to sed
    [[ -t 1  && ${_term_n_colors:-2} -ge 8 ]] &&
        tree_args+=( '-C' )

    # sed script to trim the cruft of the --fromfile output
    # - in particular, tree prints the file name as the root directory, which is '.'
    #   when reading from stdin, and that can look non-sensical.
    # - it also prints a summary at the end, which may or may not be necessary
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

    fd "$@" \
        | command tree "${tree_args[@]}" --fromfile . \
        | command sed -E "$tree_filt"
}
