# Mounting remote shares with rclone, sshfs, gio, etc.

# TODO
# - give mnt the ability to mount borg shares as well
# - try mounting ftps shares using curlftpfs:
#   https://wiki.archlinux.org/title/CurlFtpFS
#   or rclone, but it says it doesn't support server side copy:
#   https://rclone.org/ftp/#limitations
# - add support for archivemount
# - note, to mount a USB removable drive, use e.g.
#    udisksctl mount -b /dev/sdc1

if [[ -n $( command -v rclone ) ||
      -n $( command -v sshfs ) ||
      -n $( command -v gio ) ]]
then
    alias sshfs-mnt='mnt -s'
    alias rclone-mnt='mnt -r'
    alias rmnt="mnt"

    mnt() {

        : "Mount remote shares with rclone, sshfs, or gio

        Usage

          ${FUNCNAME[0]} [opts] [-l | destination]

        Defaults to sshfs, then rclone, then gio.

        Options

          -s : use sshfs
          -r : use rclone
          -g : use gio
          -l : list mounts
          -u : unmount

        Configured Destinations:

          - squamish
          - nemo
          - nemo-backup

        Notes

          - on mounting to /media instead of /run/media, see [arch wiki](https://wiki.archlinux.org/title/Udisks) note on UDISKS_FILESYSTEM_SHARED
          - but I'm using /mnt instead, since that's explicitly the domain of the sys-admin
          - see the same arch wiki page for cleaning stale mountpoints at boot using tmpfiles.d
        "

        [[ $# -eq 0  ||  $1 == @(-h|--help) ]] &&
            { docsh -TD; return; }

        # Notes on mount-point dir, /media or /mnt:
        # - Recent versions of udisks may mount to /run/media, rather than /media.
        #   Set UDISKS_FILESYSTEM_SHARED to force /media.
        #
        # - A user dir like /media/hud may be given an ACL like:
        #     USER   root      rwx
        #     GROUP  root      ---
        #     mask             r-x
        #     user   hud       r-x
        #     other            ---
        #   The mask limits the perms of all named users and groups other than the owner.
        #
        # - I will use /mnt/remote/<dest> for remote mounting with rclone, sshfs, and gio,
        #   and allow user rwx perms on it, to allow mounting fuse mounts into it as user:
        #     sudo mkdir /mnt/remote
        #     sudo chmod 0700 /mnt/remote
        #     sudo setfacl -m u:$USER:rwx /mnt/remote
        #   This allows user file creation deletion inside the dir; files are created with
        #   typical user ownership and permissions, e.g. 'andrew:andrew'.

        # ensure clean return
        trap '
            trap-err $?
            return
        ' ERR

        trap '
            unset -f _chk_mntpt _add_report
            trap - err return
        ' RETURN

        ## Parse args, determine command and action
        local action=mount
        local rcmd rcmds=( sshfs rclone gio )

        # default command is first of the list
        for rcmd in "${rcmds[@]}"
        do
            [[ -n $( command -v "$rcmd" ) ]] &&
                break
        done ||
            err_msg 3 "no valid command in '${rcmds[*]}'"

        # parse option flags
        local flag OPTARG OPTIND=1

        while getopts ":grslu" flag
        do
            case $flag in
                ( g | gio ) rcmd=gio ;;
                ( r | rclone ) rcmd=rclone ;;
                ( s | sshfs ) rcmd=sshfs ;;
                ( l ) action=list ;;
                ( u ) action=unmount ;;
                ( \? )
                    err_msg 2 "unrecognized option: '-$OPTARG'"
                    return ;;
                ( : )
                    err_msg 2 "option requires arg: '-$OPTARG'"
                    return ;;
            esac
        done
        shift $(( OPTIND - 1 ))


        ### Just list mounts if requested
        # - list all, instead of adding rcmd to the mount-point name
        if [[ $action == list ]]
        then
            local report

            _add_report() {

                [[ -z $2 ]] &&
                    return 0

                report+=$'\n'"${1}:"$'\n'
                report+=$( sed 's/^/  /' <<< "$2" )$'\n'
            }

            _add_report 'rclone mounts' "$( mount | grep rclone || true )"
            _add_report 'sshfs mounts'  "$( mount | grep sshfs || true )"
            _add_report 'gio reports'   "$( gio mount -l )"

            [[ -z ${report:-} ]] && report="No mounts found."

            printf '%s\n' "${report-}"
            return
        fi


        # Can't go further without remote destination
        [[ $# -gt 0 ]] ||
            err_msg 2 "destination name required unless listing"


        ### Define remote url
        # - rem_host    : FQDN of the destination
        # - rem_user    : login name for destination
        # - rem_path    : initial path on remote host
        # - rem_uri     : URI of the destination for the chosen protocol (e.g. user@host:path)
        # - dest_tag    : name used in the mountpoint to represent the destination
        # - dest_nm     : name, alias, or dir provided by the user to indicate the destination
        # - loc_mntsdir : local dir the holds mount points created by this function
        # - loc_mntpt   : particular mount-point dir to use on this run
        local rem_host rem_user rem_path rem_uri
        local loc_mntsdir='/mnt/remote' loc_mntpt
        local dest_tag dest_nm=$1
        shift

        # ensure mountpoint dir is writable
        # - consider defaulting to ~/Mounts, or similar
        [[ -d $loc_mntsdir  &&  -w $loc_mntsdir ]] ||
            err_msg 9 "not writable: '${loc_mntsdir}'"


        case $dest_nm in
            # Setting the host and user are important for sshfs and gio. However, for
            # rclone, this information is only used to construct the name of the
            # mount-point, whereas the actual user and host are pulled from rclone.conf,
            # and the dest_tag should match the remote name (or alias) in that file. If
            # not set, the dest_tag will be taken as the first element of rem_host.
            ( squamish | squam )
                rem_host=squamish.in.spinup.ca
                rem_user=andrew
            ;;
            ( nemo | hud )
                rem_host=nemo.in.spinup.ca
                rem_user=hud
            ;;
            ( nemo-backup )
                rem_host=nemo.in.spinup.ca
                rem_user=hud
                rem_path=/mnt/backup
                dest_tag=nemo-backup
            ;;
            ( * )
                # unknown alias
                if  [[ $action == unmount  &&  -d $dest_nm ]]
                then
                    # asking to unmount a directory
                    # - call fusermount below for rclone and sshfs
                    # - could also check whether name is abc@def, and get dest_tag from it
                    # just define loc_mntpt and let the unmount code below take care of it
                    loc_mntpt=$dest_nm

                else
                    # suggest list of remotes from rclone.conf
                    local rmt_list
                    rmt_list=$( grep '^\[' ~/.config/rclone/rclone.conf \
                                    | tr -d '[]' \
                                    | tr '\n' ':' \
                                    | sed '
                                        s/:$//
                                        s/:/, /g
                                      ' )

                    err_msg 2 "destination not recognized: '$dest_nm'" \
                        "list from rclone.conf: $rmt_list"
                fi
            ;;
        esac

        # Define local mount-point dir
        # - loc_mntpt may have been defined to unmount a dir, above
        [[ -v loc_mntpt ]] || {

            [[ -v dest_tag ]] ||
                dest_tag=${rem_host%%.*}

            loc_mntpt=${loc_mntsdir}/${rem_user}@${dest_tag}
        }

        _chk_mntpt() {

            # ensure mountpoint is an empty dir that exists
            if [[ ! -e $loc_mntpt ]]
            then
                /bin/mkdir "$loc_mntpt"
            else
                mtdir "$loc_mntpt"
            fi
        }


        if  [[ $action == unmount  &&  $rcmd == @(rclone|sshfs) ]]
        then
            # rclone and sshfs rely on fuse for unmount

            local mnt_ln
            if mnt_ln=$( command grep "${loc_mntpt%/}" < <( mount ) )
            then
                # directory is known mountpoint
                command grep -q 'fuse' <<< "$mnt_ln" \
                    || { err_msg 5 "not a fuse mount: '$loc_mntpt'"; return; }

                if ( set -x; fusermount -zu "$loc_mntpt"; )
                then
                    /bin/rmdir "$loc_mntpt"

                    # report any remaining mounts in mntsdir
                    local flist
                    flist=$( command sed 's/^/  /' < \
                                <( command find "$loc_mntsdir" -mindepth 1 -maxdepth 1 -name '[!.]*' ) )

                    if [[ -n $flist ]]
                    then
                        printf >&2 '%s\n' \
                            "Remaining mount-points:" \
                            "$flist"
                    else
                        printf >&2 '%s\n' \
                            "No additional mount-points found in ${loc_mntsdir}"
                    fi
                fi

            elif [[ $loc_mntpt == ${loc_mntsdir}/* ]] \
                    && mtdir "$loc_mntpt"
            then
                # stale mount-point
                /bin/rmdir "$loc_mntpt"

            else
                err_msg 6 "not a recognized mount point: '$loc_mntpt'"
                return
            fi

        elif [[ $rcmd == rclone  &&  $action == mount ]]
        then
            # rclone mounts configured in ~/.config/rclone/rclone.conf
            _chk_mntpt

            # mount options
            local mopts=()
            # - rclone automatically follows symlinks on the dest unless you use then
            #   config option skip_links
            # - monitor output in daemon mode with --log-file and --log-format=pid,...
            # - use '--devname string' to set the device name sent to FUSE for mount
            #   display (default remote:path)
            # - use --allow-root or --allow-other to allow access by sudo or daemons, etc.
            mopts+=( --allow-other )
            # - send to background
            mopts+=( --daemon )
            # - buffer files to disk to support normal file system operations (e.g. seeking in files)
            mopts+=( --vfs-cache-mode writes )

            ( set -x; rclone mount "${mopts[@]}" "$dest_tag": "$loc_mntpt"; ) &&
                sed >&2 "s:$HOME:~:" <<< "Mounted ${dest_tag} at '${loc_mntpt}'."

        elif [[ $rcmd == sshfs  &&  $action == mount ]]
        then
            # sshfs: sshfs [user@]host:[dir] mountpoint
            rem_uri=${rem_user}@${rem_host}:${rem_path-}

            _chk_mntpt

            # mount options
            # - refer to man pages for sshfs, ssh, ssh_config, and sftp
            # - consider reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,
            #   per man pages and [answer](https://askubuntu.com/a/716618/52041)
            local moptstr mopts=()

            # map the remote user's UID/GID to the UID/GID of the mounting user
            mopts+=( "idmap=user" )

            # present symlinks on the server as regular files on the client
            # - see also transform_symlinks
            mopts+=( "follow_symlinks" )

            # preferred encryption method
            mopts+=( "Ciphers=aes192-ctr" )

            # prevent errors on renaming across filesystem boundaries
            # - e.g. mv in or out of the mount (per lf docs, and 'man sshfs')
            mopts+=( "workaround=renamexdev" )

            # moptstr from mopts array, as in the join_by() func
            moptstr="${mopts[0]}" &&
                unset "mopts[0]"
            moptstr+=$( printf '%s' "${mopts[@]/#/,}" )

            ( set -x; sshfs -o "$moptstr" "$rem_uri" "$loc_mntpt"; ) &&
                sed >&2 "s:$HOME:~:" <<< "Mounted ${dest_tag} at '${loc_mntpt}'."

        elif [[ $rcmd == gio ]]
        then
            rem_uri=sftp://${rem_user}@${rem_host}${rem_path:+/${rem_path}}

            if [[ $action == unmount ]]
            then
                # remove symlink and unmount within gio-land
                [[ -L $loc_mntpt ]] &&
                    /bin/rm -v "$loc_mntpt"

                ( set -x; gio mount -u "$rem_uri"; )

            elif [[ $action == mount ]]
            then
                # for GIO, loc_mntpt will be a symlink
                _chk_mntpt
                /bin/rmdir "${loc_mntpt}"

                if ( set -x; gio mount "$rem_uri"; )
                then
                    ln -s "/run/user/$UID/gvfs/sftp:host=${rem_host},user=${rem_user}" "${loc_mntpt}"
                    sed >&2 "s:$HOME:~:" <<< "Mounted ${dest_tag} using ${rcmd}, symlinked to '${loc_mntpt}'."
                fi
            fi
        fi
    }
fi

