st-rgui() {

    : """Start remote syncthing GUI in browser

    Usage: st-rgui [-n]

      - with '-n' connects from outside the Hawthorne network
      - currently, always connects to nemo
    """

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
	    { docsh -TD; return; }

    local port_args hostnm='hud@nemo'

    # option -n
    [[ ${1-} == -n ]] && {
        port_args=( -o port=51022 )
        hostnm='hud@spinup.ca'
        shift
    }

    local ssh_cmd
    ssh_cmd=$( builtin type -P ssh ) \
        || return 5

    # set up the tunnel: bind localhost:lport to nemo's local port 8384
    # - `ssh -fNL ...` runs no command and goes to background immediately
    # - `ssh -fL ... sleep 300` waits for 5 min for a program to start using the
    #   tunnel, and exits if nothing starts using it
    local lport=58384 ssh_args

    ssh_args=( -fL "localhost:${lport}:localhost:8384" )
    ssh_args+=( "${port_args[@]}" )
    ssh_args+=( "$hostnm" )
    ssh_args+=( sleep 300 )

    if "$ssh_cmd" "${ssh_args[@]}"
    then
        printf >&2 '\n%s\n' "View remote syncthing gui at <http://localhost:$lport>"

    else
        local -i ssh_ec=$?
        printf >&2 '%s\n' "An error occurred"
        printf >&2 '%s\n' "Output of 'lsof -i :$lport':"
        lsof -i ":$lport"
        return $ssh_ec
    fi
}
