str_trim() {

    [[ $# -gt 0 && $1 == @(-h|--help) ]] && {

        : "Trim whitespace from start and end of a string

        Accepts a string as an argument or on STDIN, and uses a sed script to trim
        horizontal whitespace characters from the start and end. These are commonly
        space and tab characters, but not newline. Outputs the trimmed string on stdout.

        Examples

          str=\$'\\t\\t abc def '
          printf ' :%s:\n' \"\$( echo \"\$str\" )\"
          # :                abc def :
          printf ' :%s:\n' \"\$( ${FUNCNAME[0]} \"\$str\" )\"
          # :abc def:

          # can be similarly used as ...
          echo \"\$str\" | ${FUNCNAME[0]}
          ${FUNCNAME[0]} < <( echo \"\$str\" )
          ${FUNCNAME[0]} <<< \"\$str\"
        "
        docsh -TD
        return
    }

    local filt

    filt="
        s/^[[:blank:]]+//
        s/[[:blank:]]+$//
    "

    if [[ $# -gt 0 ]]
    then
        sed -E "$filt" <<< "$@"
    else
        sed -E "$filt"
    fi
}
