if [[ -n $( command -v gio ) ]]
then
    # Gnome IO trash functionality
    # - for help, use 'gio help trash', or 'man gio'
    alias gtrash="gio trash"
    alias gtrash-ll="gio list -lh trash://"
    alias gtrash-ls="gio trash --list"

    # NB, compared to gio, there is more functionality available in the trash-cli
    # package, and it works in bind mounts and btrfs subvolumes, unlike gio. Refer to
    # trash-wrapper function for trash-cli as well.
fi
