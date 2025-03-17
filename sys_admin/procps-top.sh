if [[ $( command top --version 2>/dev/null ) == *procps-ng* ]]
then
    # Linux top (from procps package)
    #  -o : order the display by key (default pid)
    alias top-cpu="top -ocpu"

    top-sb() {

        : "prevent top from clobbering the scrollback buffer"

        tput smcup
        top "$@"
        tput rmcup
    }
fi
