path_check_add () {

    [[ $# -lt 1 || $1 =~ ^(-h|--help)$ ]] &&
    {
        docsh -DT "Check directory existence and add to PATH variable.

            Usage

            path_check_add [options] path [path2 [path3 ...]]

            - Multiple path args are all added to PATH by default, maintaining the order.
            - If path is already in PATH, a warning is issued and the path is skipped,
                unless using -m or -q.

            Options:
            -f or -b : add to front (default) or back of PATH
            -m       : if path already in PATH, move it (removes and adds to front or back)
            -o       : adds only one (the first existing) of multiple path arguments
            -q       : suppress warning in the event that path is already in PATH
            -s <s>   : add subdirectories named <s>, to maxdepth 3
        "
        return 0
    }

    local fb=f move_pp one_pp quiet subdir maxd
    local pp pps cpp dn
    local OPT OPTARG OPTIND=1

    while getopts "fbmoqs:" OPT
    do
        case $OPT in
            ( f | b )
                fb=$OPT ;;
            ( m )
                move_pp=True ;;
            ( o )
                one_pp=True ;;
            ( q )
                quiet=True ;;
            ( s )
                subdir=$OPTARG; maxd=3 ;;
            ( '?' )
                err_msg 1 "OPT: '$OPT'"
                return 1 ;;
        esac
    done
    shift $(( OPTIND - 1 ))  # remove parsed options, leaving positional args

    (( $# )) || {
        err_msg 2 "path_check_add requires path argument"
        return 2
    }

    # populate pps array, either straight from args, or from subdir search
    if [[ -z ${subdir-} ]]
    then
        pps=("$@")

    else
        for pp in "$@"
        do
            [[ ! -d $pp ]] && continue

            # add subdirs called $subdir within each dir arg
            while IFS='' read -r -u 3 -d '' dn
            do
                pps+=("$dn")

            done 3< <(find "${pp%/}" -maxdepth $maxd -name "$subdir" -type d -print0)
        done
    fi

    for pp in "${pps[@]}"
    do
        if [[ -d $pp ]]
        then
            pp=${pp%/}

            # check whether pp is already in PATH
            if path_has "$pp"
            then
                # pp already in PATH

                if [[ -n ${move_pp-} ]]
                then
                    # strip pp from PATH so it can be added to the preferred spot
                    PATH=$( path_rm "$pp" )  \
                        || return $?
                else
                    # warn and skip pp
                    [[ ${quiet-} != True ]] &&
                        err_msg w "already in PATH: '$pp'; skipped"

                    if [[ ${one_pp-} == True ]]
                    then break
                    else continue
                    fi
                fi

            else
                # check whether pp is a symlink to an existing path
                # - e.g. in the case /bin is a symlink to /usr/bin
                cpp=$( builtin cd "$pp"; pwd -P )

                if  [[ $cpp != $pp ]] &&
                    path_has "$cpp"
                then
                    # symlink target of pp already in PATH
                    # warn, but don't skip pp
                    [[ ${quiet-} != True ]]  \
                        && err_msg w "symlink target already in PATH: '$pp'"
                fi
            fi

            # add pp to PATH
            if [[ $fb == f ]]
            then export PATH=$pp:$PATH
            else export PATH=$PATH:$pp
            fi

            [[ ${one_pp-} == True ]] && break
        fi
    done

    return 0
}
