# Borg Backup

# Borg Backup environment setup
# - the borg-go command and associated scripts should be symlinked from ~/.local/bin/
#   (see bgo_links.sh). Then it is run using `sudo borg_go ...` if sudoers
#   allows, or `sudo $(command -v borg_go) ...` if necessary. For more info on
#   permissions etc, see the "Backup Software Notes" file.
# - BORG_CACHE_DIR and BORG_SECURITY_DIR are set in the borg-go script to be within
#   root's HOME.
if [[ -n $( command -v borg ) ]]
then
    export BORG_CONFIG_DIR=~/.config/borg
    export BORG_LOGGING_CONF="$BORG_CONFIG_DIR/borg_logging.conf"
    export BORG_REPO

    case $( hostname -s ) in
        ( [Ss]quamish )
            BORG_REPO='ssh://hud@nemo/mnt/backup/borgbackup_squamish_macos_repo'
        ;;
        ( the-glen )
            BORG_REPO='ssh://hud@nemo/mnt/backup/borgbackup_the.glen_laptop_repo'
        ;;
        ( swamp-deb )
            BORG_REPO='ssh://hud@nemo/mnt/backup/borgbackup_swamp-deb_crbook_repo'
        ;;
        ( erikson | mendeleev )
            BORG_REPO='/mnt/hc_backup'
            BORG_MNT_REQD=1              # need to run borg_mount-check in borg_go
        ;;
        ( nemo )
            BORG_REPO='hud@localhost:/mnt/backup/borgbackup_nemo_htpc_repo'
        ;;
    esac
fi


# Borgmatic -- not using this any more, preferring borg_go.sh
# - to show the full borg command call, use verbosity 2
if [[ -n $(command -v borgmatic) ]]
then
    alias borgmatic="borgmatic -c \"${BORG_CONFIG_DIR}/borgmatic_cfg.yaml\""

    borgmatic_go() {
        # NB this works because ~ in paths is replaced by *calling* user's HOME
        [[ $# -eq 0 ]]  \
            && { echo >&2 "Typical cmds: create --files --stats prune check"
                 return 0; }

        sudo -EH "borgmatic" -c "${BORG_CONFIG_DIR}/borgmatic_cfg.yaml" -v 0 \
                    --log-file "${BORG_CONFIG_DIR}/borgmatic_log.txt" \
                    --log-file-verbosity 1 "$@"
    }
fi
