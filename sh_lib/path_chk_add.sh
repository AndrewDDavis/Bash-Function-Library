path_chk_add ()
{
    [ $# -eq 0 ] || [ "$1" = -h ] &&
    {
        # in sh mode, the only array is the positional params
        set -- "Add new path to front of PATH if it exists and is not already included" \
               "" \
               "Usage: path_chk_add [opts] '/path/to/add/bin' ..." \
               "" \
               "Return codes:" \
               "  1 : dir already in path" \
               "  2 : non-existent dir" \
               "" \
               "Options:" \
               "  -z : return status 0 even if path is not a directory or is already on PATH" \
               ""

        printf '\n'
        printf '  %s\n' "$@"
        return
    }

    # Check if user id is 1000 or higher
    # [ "$(id -u)" -ge 1000 ] || return

    # Return statuses of dir and path checks
    # - NB 'local' is not strictly POSIX, but is supported by bash, zsh, dash, ash, ...
    local rs_d=2
    local rs_p=1

    # Options
    local OPT OPTARG OPTIND=1

    while getopts 'z' OPT
    do
        case $OPT in
            ( z )
                rs_d=0
                rs_p=0
                ;;
        esac
    done
    shift $((OPTIND - 1))

    # Remaining args should be dirs to check
    local pp rs=0

    for pp in "$@"
    do
        # Check dir exists
        [ -d "$pp" ] ||
        {
            [ $rs = 0 ] && rs=$rs_d
            continue
        }

        # Check that pp is not already in PATH
        # - multiple tests needed so e.g. /bin doesn't match ...:/usr/bin:...
        # - could also use grep, like:
        #   echo "$PATH" | grep -Eq "(^|:)$pp(:|$)" && continue
        case "$PATH" in
            ( "$pp" | "$pp:"* | *":$pp" | *":$pp:"* )
                [ $rs = 0 ] && rs=$rs_p
                continue
                ;;
        esac

        if [ -n "${PATH-}" ]
        then
            PATH="$pp:$PATH"
        else
            PATH="$pp"
            export PATH
        fi
    done

    return $rs
}
