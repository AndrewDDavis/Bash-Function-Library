# macOS
[[ -n $( command -v osascript ) ]] &&
    alias logout-mac="osascript -e 'tell application \"System Events\" to log out'"

# Gnome
[[ -n $( command -v gnome-session-quit ) ]] &&
    alias logout-de="gnome-session-quit"
