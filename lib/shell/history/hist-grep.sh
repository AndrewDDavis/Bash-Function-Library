# TODO:
# - also highlight the pattern match in the usual way for grep

hist-grep() {

    : "Search the shell history file(s) for occurrences of a pattern

        Pattern matching is performed by \`grep -E\`, and the glob for history files
        is \`~/.bash*history\`.
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local grep_cmd sed_cmd grep_out rxc sfilt fn hfns

    grep_cmd=$( builtin type -P grep ) \
        || return 4

    sed_cmd=$( builtin type -P sed ) \
        || return 5

    # regex to match commands
    rxc='((sudo|export|local|declare|typeset)[ ]+(-[^ ]+[ ]+)?)?[^ =]+=?'

    hfns=( ~/.bash*history )

    for fn in "${hfns[@]}"
    do
        # search, then filter output
        if grep_out=$( "$grep_cmd" -E "$@" "$fn" )
        then
            # report history filename (underlined)
            printf '\n%s:\n\n' "${_cul-}${fn/#$HOME/\~}${_cru-}"

            # sed filter
            sfilt="
                # remove file name
                s|^${fn}:||

                # remove hist-grep commands?
                /^hist-grep.*/ d

                # commands get bold styling
                s/^($rxc)/${_cbo-}\1${_crb-}/

                # also bold commands following | or ;
                s/ (\||;) ($rxc)/ \1 ${_cbo-}\2${_crb-}/g
            "

            printf '%s\n\n' "$grep_out" \
                | "$sed_cmd" -E "$sfilt"
        fi
    done
}
