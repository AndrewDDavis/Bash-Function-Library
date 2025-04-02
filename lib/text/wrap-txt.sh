wrap-txt() {

    : "Wrap text

        Usage: wrap-txt [fmt-options] [file]

        Calls 'fmt -u' to reformat the text so that paragraphs wrap near the character
        limit (default 88). When no file is specified, or when file is -, standard
        input is used.

        Notable fmt options:

          -c
          : preserve indentation of first two lines

          -p STRING
          : only reformat lines beginning with STRING, and retain the prefix

          -s
          : only split long lines, do not refill

          -u
          : uniform spacing, one space between words, two after sentences

          -w N
          : maximum line width
    "

	[[ ${1-} == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    local fmt_cmd
    fmt_cmd=( "$( builtin type -P fmt )" -u -w88 ) \
        || return 9

    "${fmt_cmd[@]}" "$@"
}
