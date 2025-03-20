# mdfind on macOS
[[ $( uname -s ) == Darwin  && -n $( command -v mdfind ) ]] &&
    alias mdfindo="mdfind -onlyin"
