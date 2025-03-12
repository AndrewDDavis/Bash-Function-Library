# Command aliases for Desktop Environments and GUIs

# Allow root to run GUIs under Wayland (for BackInTime)
#[[ $XDG_SESSION_TYPE = "wayland" ]] &&
#   xhost +si:localuser:root

# macOS logout from the command line
[[ -n $( command -v osascript ) ]] &&
    alias logout-mac="osascript -e 'tell application \"System Events\" to log out'"

# Gnome
[[ -n $(command -v gnome-session-quit) ]] &&
    alias logout-de="gnome-session-quit"

# XDG
[[ -n $(command -v xdg-open) ]] &&
    alias xof="xdg-open"

[[ -n $(command -v x-www-browser) ]] &&
    alias xou="x-www-browser"

[[ -n $(command -v x-terminal-emulator) ]] &&
    alias xot="x-terminal-emulator"

# Clipboard
[[ -n $(command -v xclip) ]] &&
    alias paste-xclip="xclip -selection clipboard -o"

[[ -n $(command -v xsel) ]] &&
    alias paste-xsel="xsel -bo"

[[ -n $(command -v wl-paste) ]] &&
    alias paste-wl="wl-paste"
