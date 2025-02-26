path_check_symlink () {

    [[ $# -lt 2 || $1 =~ ^(-h|--help)$ ]] &&
    {
        docsh -DT "Check whether two paths are symlinked and both on PATH

            Usage

            path_check_symlink [options] path1 path2

            -q : suppress warning if paths are symlinked
            -r : remove path2 if paths are symlinked
        "
        return 0
    }

    local rm_path quiet
    local pp1 pp2
    local OPT OPTARG OPTIND=1

    while getopts "qr" OPT
    do
        case $OPT in
            ( q )  quiet=True ;;
            ( r )  rm_path=True ;;
            ( '?' )  err_msg 1 "OPT: '$OPT'" || return $? ;;
        esac
    done
    shift $(( OPTIND - 1 ))  # remove parsed options, leaving positional args

    (( $# == 2 )) || {
        err_msg 2 "path_check_symlink requires 2 path arguments!"
        return 2
    }

    pp1=$( builtin cd "$1"; pwd -P )
    pp2=$( builtin cd "$2"; pwd -P )

    if [[ $pp1 == "$pp2" ]]
    then
        [[ ${quiet-} != True ]]  \
            && err_msg w "paths are symlinks: '$1', '$2'"

        if [[ ${rm_path-} == True ]]
        then
            if [[ -L $1 ]]
            then rm_path=$1
            else rm_path=$2
            fi

            [[ ${quiet-} != True ]] &&
                err_msg i "Removing path due to symlink dupes: '$rm_path'"

            PATH=$( path_rm "$rm_path" )
        fi
    fi

    return 0
}
