path_rm ()
{
    # remove pp from PATH and return new PATH
    local pp=$1

    # first check whether pp is the whole path, first item, or last item
    # - if not, use sed to strip with the preceding colon
    case "$PATH" in
        ( "$pp" )
            PATH=''
            ;;
        ( "$pp:"* )
            PATH=${PATH#"$pp:"}
            ;;
        ( *":$pp" )
            PATH=${PATH%":$pp"}
            ;;
        ( *":$pp:"* )
            # - check for @ in pp first, for safe sed command
            [[ $pp != *@* ]] ||
            {
                err_msg 2 "@ in pp, unable to remove path: '$pp'"
                return 2
            }

            PATH=$( sed "s@:${pp}@@" <<<"$PATH" )
            ;;
        ( * )
            err_msg 2 "pp not found in PATH: '$pp'"
            return 2
            ;;
    esac

    printf '%s\n' "$PATH"
}

# AWK version
# awk '{ gsub("/home/andrew/Sync/Code/python/misc",""); gsub(/:/,"\n"); print; }' <<< "$PATH"
