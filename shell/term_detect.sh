term_detect() {

    [[ ${1-} == @(-h|--help) ]] && {

        : "Try to detect current terminal emulator, and set TERM_PROGRAM"
        docsh -TD
        return
    }

    # TODO: check this answer for ideas: https://askubuntu.com/a/476705/52041
    #       also this for tmux: https://unix.stackexchange.com/a/608335/85414
    #
    # other potentially useful ideas
    #
    # check for X
    #[[ -z ${DISPLAY} && -z ${WAYLAND_DISPLAY} ]]
    #
    # check tty
    # - virtual term emulators typically use /dev/pts/... on Linux


    # If TERM_PROGRAM is already set, leave it alone
    # - also don't try this if we're in an SSH session
    # - macOS sets TERM_PROGRAM=Apple_Terminal
    [[ -n ${TERM_PROGRAM-}  || -n ${SSH_CLIENT-} ]] &&
        return

    ### Try to detect known terminal emulators

    # Get the name of the shell's parent process
    # - use read to strip leading whitespace
    local pcmd ppid
    read -r ppid <<< "$( ps -o 'ppid=' -p $$ )"
    pcmd=$( ps -o 'command=' -ww -p "$ppid" )

    if  [[ $pcmd == *'bin/vshd '* ]] \
            && [[ $BROWSER == /usr/bin/garcon-url-handler ]]
    then
        # In ChromeOS Container, likely running CrOS Terminal
        # - also [[ -r /dev/.cros_milestone ]]
        # - also [[ -r /opt/google/cros-containers/etc/lsb-release ]]
        export TERM_PROGRAM=ChromeOS_Terminal
    fi

    # As a last resort, could use a hash of the machine ID to identify the particular
    # host we're running on; see https://man.archlinux.org/man/sd_id128_get_machine_app_specific.3.en
}
