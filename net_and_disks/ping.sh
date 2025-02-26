### Network Troubleshooting and Diagnostics

ping-ci() {
    docstr="ping 10 times at 250 ms

    Usage

      ping-ci [options] <address>

      - for iputils ping, report late responses using -O
      - any further arguments are passed to ping
    "

    # print docstrings
    [[ $# -eq 0 || $1 =~ ^(-h|--help)$ ]] && {

        docsh -TD "$docstr"
        return 0
    }

    # parse args, define vars
    local opts=(-c 10 -i 0.25)

    ping -c 1 -O 127.0.0.1 &>/dev/null && {
        opts+=(-O)
    }

    # main operation
    ping "${opts[@]}" "$@"
}

ping-hops() {
    docs=(
    'determine the number of hops to a host by using successively lower TTL pings'
    'option -t <n>: start value of TTL (default 24)'
    ' - any further arguments are passed to ping'
    )

    # print docstrings
    [[ $# -eq 0 || $1 == -h || $1 == --help ]] && {
        printf '  %s\n' "${docs[@]}"
        return 0
    }

    # args and vars
    local -i ttl=24
    [[ $1 == -t ]] && {
        ttl=$2
        shift 2
    }

    # define ping args other than ttl
    local -a pargs
    local -f ptest
    pargs=(-c 3 -i 0.5 "$@")
    ptest() {
        printf '%s\r' "testing ttl=${ttl}...   "
        ping -t $1 "${pargs[@]}" >/dev/null
    }

    # loop with decreasing ttls until failure
    echo "starting ping-test at ttl=$ttl..."
    local -i pec=0
    while (( $pec == 0 ))
    do
        if ptest $ttl
        then
            ttl=ttl-2
        else
            pec=$?
        fi
    done

    ttl=ttl+1
    ptest $ttl || {
        ttl=ttl+1
    }

    echo "Host ${@:(-1)} is estimated to be $ttl hops away."
}
