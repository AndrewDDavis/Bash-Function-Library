### Interactive processes

if top --version 2>/dev/null | grep -q procps-ng
then
    # Linux top (from procps package)
    #  -o : order the display by key (default pid)
    alias top-cpu="top -ocpu"

    # prevent top from clobbering the scrollback buffer
    top-sb() {
        tput smcup
        top "$@"
        tput rmcup
    }
fi


# htop
# ...
