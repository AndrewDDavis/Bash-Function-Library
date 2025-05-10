# deps
import_func array_match std-args \
    || return

alias rsync-local='rsyncx --local'
alias rsync-remote='rsyncx --remote'
alias rsync-check='rsyncx --diff'

# TODO:
#
# - incorporate mv functionality from the old rsyncx:
#
#   mv : simulate moving files
#   - adds --remove-source-files, --progress to the gp options
#   - rsync removes files, then find is used to delete empty directories
#     after a successful transfer.
#
#   ( mv )
#   rs_opts=( "$gp_args" --remove-source-files  \
#             --info=remove --progress          \
#             "${rs_opts[@]}" )
#
#   (
#       [[ $_v -gt 0 ]] && set -x
#       "$rsync_cmd" "${rs_opts[@]}" "$@"
#
#   ) || rs_ec=$?
#
#   # finish pruning empty dirs after mv
#   if [[ $cmd == mv  &&  $rs_ec -eq 0 ]]
#   then
#       # there are as many src dirs as arguments, except the target
#       c=$(( $# - 1 ))
#       printf '\n%s\n' "Pruning empty dirs from ${*:1:$c}..."
#
#       for sfn in "${@:1:$c}"
#       do
#           [[ -d "$sfn" ]] && {
#
#               find "$sfn" -type d -empty -print -delete
#           }
#       done
#
#   elif [[ $rs_ec -ne 0 ]]
#   then
#       err_msg $rs_ec "rsync exited with code $rs_ec"
#       return $rs_ec
#   fi



rsyncx() {

    :  "Wrapper function for rsync with useful modes

        Usage: rsyncx [rsync-opts] SRC [... DEST]

        This wrapper function runs rsync with a set of options that are sensible in most
        situations, and provides a few additional options for common situations.
        Otherwise, this function passes all of its arguments unchanged to rsync. Note
        that remote sources or destinations should take the form [user@]host:dir. That
        is, they should include a colon. If DEST is omitted, the contents of SRC are
        listed.

        By default, rsyncx includes the flags turned on by -a (i.e. -rlptgoD), as well
        as -AXU. These are a sensible starting point for almost any transfer. They can
        be selectively negated, like all other options, by using e.g. --no-o. Note that
        -o and -D only apply when running as super-user on the receiving end, or with
        --super. The -N (--crtimes) option is not used, since it's not available on the
        Debian compiled rsync.

        In addition, rsyncx makes the following flags available. When SRC and DEST are
        both local, the --local flag is automatically applied. When one of SRC and DEST
        is remote (detected by the required colon), the --remote flag is applied.

          --local
          : This adds -H to the defaults, to preserve hard-links.

          --remote
          : Adds -z and --partial to the defaults. This compresses data in transit, and
            preserves partially transferred files. NB, rsync has a good default list of
            compression exclusions. The --info=progress2 option is also added to show
            overall transfer progress.

          --diff
          : Check for differences among files, but don't make any transfers. In addition
            to the defaults, this adds: -nci --delete. Refer to the notes on -i below:
            any files that are only on DEST will be marked with *deleting, and any files
            that are only on SRC will be marked with xx+++++++++.

          --rsbak
          : Create backup files, using the options:
            --backup --suffix='.rsbak'
            Consider also the --backup-dir option.

          --mv
          : ...

        Info Reporting Options

        By default, rsync is quiet. To show some basic info including a listing of
        changed files, -v can be used to turn on a sensible set of --info flags. Using
        -vv shows very detailed information about the transfer and the application of
        the filter rules.

        This function adds --info=del,stats to the command-line when -v is not used.
        This prints file deletions and a short data transfer summary. -h is also added
        for human readable data units.

        Use -i to print a summary line for each changed file. Using -ii also prints a
        line for unchanged files. Refer to the rsync manpage under --itemize-changes to
        decode the summary line, and also consider the --log-file option. Briefly:

          - If a file is to be removed, the summary line is * followed by the
            word deleting. Otherwise, the first char is the update type. It may be < or
            > for files sent and received, . for a file with unchanged content, or c for
            a directory to be created.

          - The second char is the file type, which may be f, d, L, D, or S.

          - The remaining characters are + for a newly created file. Otherwise, any that
            are not . indicate what will be updated, or why the file is being
            transferred, e.g. c for checksum, s for size, t for time, etc.

        Issue '--info=help' to print the rsync's info flag options that may be used. The
        following options are recommended to achieve the noted effects:

          --info=name0
          : Suppress the file listing while using -v or -vv.

          --info=name2 or -vv
          : Print a line for each unchanged file.

          --info=skip or -vv
          : Print a line for each skipped file when using -u (--update).

          --stats or --info=stats2
          : Print a detailed file transfer summary.

          --debug=filter or -vv
          : Print the results of applied filter rules.

        Filter Rules

        Rsync builds an ordered list of filter rules as specified on the command-line
        and found in relevant files. The default is for all files within the transfer
        root to be included.

        This function honours the filter rules found in '~/.config/rsync/default.rules',
        if that file exists. They are applied using the merge-files syntax for the
        '--filter' option, and are intended to exclude machine-specific hidden files,
        such as '.DS_Store' and lock files. To clear the filter list, use: -f'!' on the
        command line.

        To exclude files for a single transfer, the --exclude=PATTERN option may be
        used, which is equivalent to a filter rule of -f'- PATTERN'. The patterns
        generally follow globbing rules as in other similar tools. Refer to the PATTERN
        MATCHING RULES section of the rsync manpage for details and examples.

        To include only certain files in a transfer, include rules are needed for the
        file and any parent directories within the transfer root. Then a trailing
        exclusion rule that matches all files would be specified, e.g.:

          -f'+ x/' -f'+ x/y/' -f'+ x/y/file.txt' -f'- *' x host:/tmp/

        Exclude rules both hide files on the sending side and protect files on the
        receiving side. Similarly, include rules both show (or expose) files on the
        sending side, and risk files on the receiving side.

        The option -F may be used apply per-directory filter rules found in files
        named '.rsync-filter'. With -F, the .rsync-filter files may be found in parent
        directories of the transfer root, as well as its subdirectories. Refer to the
        MERGE-FILE FILTER RULES section of the rsync manpage.
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] \
        && { docsh -TD; return; }

    # rsync path
    local rs_cmd
    rs_cmd=( "$( builtin type -P rsync )" ) \
        || return 5

    # default filtering rules
    [[ -r ~/.config/rsync/default.rules ]] \
        && rs_cmd+=( -f ". ${HOME}/.config/rsync/default.rules" )

    # Run std-args to parse rsync args (makes _stdopts)
    # - specify short and long opts that require an arg
    local opt_args pos_args
    so='MBeT@f'
    lo="address bwlimit config dparam port log-file log-file-format sockopts include-from \
        files-from copy-as address port sockopts outbuf remote-option out-format log-file \
        log-file-format password-file early-input bwlimit stop-after stop-at write-batch \
        only-write-batch read-batch protocol iconv checksum-seed info debug stderr \
        backup-dir suffix chmod checksum-choice block-size rsh rsync-path max-delete \
        max-size min-size max-alloc partial-dir usermap groupmap chown timeout contimeout \
        modify-window temp-dir compare-dest copy-dest link-dest compress-choice \
        compress-level skip-compress filter exclude exclude-from include"

    std-args opt_args pos_args "$so" "$lo" -- "$@" \
        || return

    # check for -v or -vv, otherwise print minimal info
    array_match -- _stdopts '-v' \
        || rs_cmd+=( --info='del,stats' )

    # check for any remote src or dest
    if array_match -s pos_args ':'
    then
        # remote
        array_match -- _stdopts '--remote' \
            || set -- --remote "$@"
    else
        # local
        array_match -- _stdopts '--local' \
            || set -- --local "$@"
    fi

    set -x
    # general purpose, sensible default for most file syncing situations
    # - NB, -s (protect-args) no longer necessary as of rsync 3.2.4
    # - my rsync on Debian testing doesn't have -N
    rs_cmd+=( -h -rlDX -pAgo -tU )

    # check for wrapper options
    local w _mv rs_args=()
    for w in "$@"
    do
        decp w
        case $w in
            ( --diff )   rs_args+=( -nci --delete ) ;;
            ( --local )  rs_args+=( -H ) ;;
            ( --remote ) rs_args+=( --partial -z --info=progress2 ) ;;
            ( --rsbak )  rs_args+=( --backup --suffix='.rsbak' ) ;;
            # ( --mv )  rs_args+=( --backup --suffix='.rsbak' ) ;;
            ( * )
                rs_args+=( "$w" )
            ;;
        esac
        shift
    done

    "${rs_cmd[@]}" "${rs_args[@]}"
    set +x
}
