# Exclude annoying files from interactive transfers
# - this uses the merge-files syntax of --filter
# - another way to do this is -F, which uses per-dir files: --filter=': /.rsync-filter'
# - note syntax to clear the include/exclude list: -f'!'
[[ -r ~/.config/rsync/default.rules ]] && {

    # shellcheck disable=SC2139
    alias rsync="rsync -f '. ${HOME}/.config/rsync/default.rules'"
}

# - good default for local files
# - my rsync on Debian testing doesn't have -N
alias rsync-local='rsync -rlDvh -pAgo -tU -XH'

# - check for differences:
alias rsync-check='rsync-local -nc --delete'

# - also note backups are a good option
#   --backup --suffix='.rsbak'
# - other useful items:
#   --itemize-changes, -i
#   --stats, for summary stats of the transfer
#   --exclude=PATTERN

rsyncx() (

    [[ $# -eq 0 || $1 =~ ^(-h|--help)$ ]] && {

        : "Wrapper function for common rsync uses.

        Usage: rsyncx <cmd> [rsync-opts] SRC ... [DEST]

        This function takes a command as its first argument, which sets rsync options
        for various common situations. The rest of the arguments are passed on to
        rsync.

        If the file '~/.config/rsync/default.rules' exists, any filter rules it contains
        are honoured by the rsync call of this function. This can be negated on the
        command line by clearing the filter list using -f'!'.

        Rsyncx Commands

          gp : general purpose, sensible default for most file syncing situations
               - uses '-vh -rlD -t -pg' (similar to -a below)
                 -v : more verbose messages
                 -h : human readable file sizes
               - NB -s (protect-args) no longer necessary as of rsync 3.2.4

          nw : network transfer options
               - adds -Pz to the gp options
                 -P : --partial (retain parts on interruption) + --progress
                 -z : compress in transit
               - NB rsync has a good default list of compression exclusions

          mv : simulate moving files
               - adds --remove-source-files, --progress to the gp options
               - rsync removes files, then find is used to delete empty directories
                 after a successful transfer.

          bk : archive options, appropriate for full system backups
               - uses -a (see below), --partial, -z, -vh
               - uses --info=progress2,name0 for overall progress without a
                 scrolling file list.

          sf : safe options, make backups of changed and deleted files
               - adds -b, --suffix=.rsx.bak to the gp args (cf. --backup-dir)

        See the rsync docs for full command usage. A few brief notes:

          - Wildcards in the arguments are handled by the shell, and this function should
            give the same results as rsync.

          - To transfer remote files, the form of SRC and DEST may be [user@]host:dir.

          - With both SRC and DEST local, rsync works as an improved copy command.

          - Providing only SRC and and not DEST lists the contents of SRC.

          - When SRC is a directory, adding a trailing slash avoids creating the
            directory on DEST, copying only the contents.

          - If any files already exist on DEST, they are updated by sending only the
            differences in the data.

        Notable Rsync Options

          -a (--archive)
          : Sensible starting point for many transfers, expanded to '-rlptgoD':
              -r : recursive
              -l : symlinks-as-symlinks (cf. -L)
              -p : preserve permissions (cf. -E, --chmod)
              -t : preserve mod-times
              -g : preserve group
              -o : preserve owner
              -D : preserve device and special files (e.g. in /dev, sometimes ~/.config)
            Note that -o and -D only apply when running as super-user on the
            receiving end, or when using --super. These and any other option can be
            negated selectively by using e.g. -a --no-o.

          -n (--dry-run)
          : perform a trial run with no changes made (cf. --list-only)

          -R (--relative)
          : preserve full file path, including 'implied directories' in src path

          --exclude=PATTERN, --include=PATTERN
          : exclude (or don't) files matching PATTERN

          -C (--cvs-exclude)
          : exclude a broad range of files that you often don't want to transfer
            between systems, such as '*.old', '*.bak', and '.git/'. Also exclude
            files listed in ~/.cvsignore or the CVSIGNORE variable. Also a file is
            ignored if it matches a pattern in a .cvsignore file in the same
            directory.

          -u (--update)
          : skip files that are newer at DEST (cf. --[ignore-]existing)

          -c (--checksum)
          : skip based on checksum, not mod-time & size (cf. --ignore-times,
            --size-only)

          --delete, --delete-excluded
          : delete extraneous files from dest dirs (delete-during is default), or
            also delete excluded files from dest dirs

          -x (--one-file-system)
          : don't cross filesystem boundaries

          -A (--acls)
          : preserve ACLs (implies --perms)

          -X (--xattrs)
          : preserve extended attributes

          -U (--atimes)
          : preserve access times (last opened)

          -N (--crtimes)
          : preserve create times (newness)

          -H (--hard-links)
          : preserve hard links

          -k (--copy-dirlinks)
          : transform symlink to dir into referent dir

          -K (--keep-dirlinks)
          : treat symlinked dir on receiver as dir

          --stats
          : give some file-transfer stats

          -i (--itemize-changes)
          : output a change-summary for all updates (consider --log-file)

          -e (--rsh=COMMAND)
          : specify command to use for remote shell (e.g. 'ssh -o port=...')

          --rsync-path=PROGRAM
          : specify the path to the rsync command to run on remote machine
        "
        docsh -TD
        return
    }

    # default to printing rsync cmd
    local _v=1

    # cmd must come first
    cmd=$1
    shift

    # collect option args
    # - collect until first non-option arg or --
    rs_opts=()

    while IFS='' read -rd '' arg
    do
        # break on non-option arg
        [[ ${arg::1} != - ]] && break

        # handle --, passing it on to rsync
        [[ $arg == -- ]] && {
            rs_opts+=( "--" )
            shift
            break
        }

        # sequester and remove opt args
        rs_opts+=( "$arg" )
        shift

    done < <( printf '%s\0' "$@" )

    # debug arg-parsing
    #echo "cmd='$cmd'"
    #echo "rs_opts:"
    #printf ':: %s\n' "${rs_opts[@]}"
    #echo "remaining args:"
    #printf ':: %s\n' "$@"

    # there must be at least one SRC arg
    [[ ! $# -gt 0 ]] && {
        err_msg 2 "at least 1 SRC arg required; got: $cmd ${rs_opts[*]}"
        return 2
    }

    # finish setting up rs_opts for cmd
    gp_args='-rlDptgvh'

    case $cmd in
        ( gp )
            rs_opts=( "$gp_args" "${rs_opts[@]}" )
        ;;
        ( nw )
            rs_opts=( "$gp_args" -Pz "${rs_opts[@]}" )
        ;;
        ( mv )
            rs_opts=( "$gp_args" --remove-source-files  \
                      --info=remove --progress          \
                      "${rs_opts[@]}" )
        ;;
        ( bk )
            rs_opts=( "$gp_args" -az --partial  \
                      --info='progress2,name0' "${rs_opts[@]}" )
        ;;
        ( sf )
            rs_opts=( "$gp_args" -b --suffix='.rsx.bak'  \
                      "${rs_opts[@]}" )
        ;;
        ( * )
            err_msg 2 "command not recognized: $cmd"
            return
        ;;
    esac

    # add default filter rules
    [[ -r ~/.config/rsync/default.rules ]] &&
        rs_opts+=( -f ". ${HOME}/.config/rsync/default.rules" )

    # run rsync
    local rsync_cmd rs_ec=0
    rsync_cmd=$( builtin type -P rsync )

    (
        [[ $_v -gt 0 ]] && set -x
        "$rsync_cmd" "${rs_opts[@]}" "$@"

    ) || rs_ec=$?

    # finish pruning empty dirs after mv
    if [[ $cmd == mv  &&  $rs_ec -eq 0 ]]
    then
        # there are as many src dirs as arguments, except the target
        c=$(( $# - 1 ))
        printf '\n%s\n' "Pruning empty dirs from ${*:1:$c}..."

        for sfn in "${@:1:$c}"
        do
            [[ -d "$sfn" ]] && {

                find "$sfn" -type d -empty -print -delete
            }
        done

    elif [[ $rs_ec -ne 0 ]]
    then
        err_msg $rs_ec "rsync exited with code $rs_ec"
        return $rs_ec
    fi

    return 0
)
