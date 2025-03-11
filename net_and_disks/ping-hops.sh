### Network Troubleshooting and Diagnostics

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
