lang_chk ()
{
    [ $# -eq 0 ] || [ "$1" = -h ] &&
    {
        # in sh mode, the only array is the positional params
        set -- "Check for valid language spec" \
               "" \
               "Usage: lang_chk <str>" \
               "" \
               "The string argument may be lang, lang_territory, or full locale" \
               "(lang[_territory][.codeset])." \
               "" \
               "Returns true if arg-1 matches a language on this machine." \
               ""

        printf '\n'
        printf '  %s\n' "$@"
        return
    }

    local ll lv rs

    if [ "$1" = -u ]
    then
        # define grep pattern to check ...utf8 and ...UTF-8 regardless of input
        ll=${2%.UTF-8}
        ll=${ll%.utf8}
        ll="^($ll.UTF-8|$ll.utf8)\$"
    else
        ll=$1
    fi

    # use locale to check for local existence of language variant
    lv=$( locale -a | egrep -m1 "$ll" ) ||
    {
        # - this handles rs=141 from the SIGPIPE signal to locale on macOS
        rs=$?
        [ $rs -eq 141 ] && true || ( exit $rs )
    }

    if [ -n "$lv" ]
    then
        printf '%s\n' "$lv"
        return 0
    else
        return 2
    fi
}
