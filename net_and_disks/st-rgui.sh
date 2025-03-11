st-rgui() {

    : "start remote syncthing GUI in browser

    - currently, always connects to nemo
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
	    { docsh -TD; return; }

    # arg1: -n : connect from outside the Hawthorne network
    local nat=false
    [[ $1 == -n ]] && nat=true


    # set up the tunnel: bind localhost:lport to nemo's local port 8384
    # - `ssh -fNL ...` runs no command and goes to background immediately
    # - `ssh -fL ... sleep 300` waits for 5 min for a program to start using the
    #   tunnel, and exits if nothing starts using it
    local lport=58384
    local ec

    if [[ $nat == true ]]
    then
        ssh -o port=51022 -fL localhost:$lport:localhost:8384 hud@spinup.ca sleep 300
        ec=$?
    else
        ssh -fL localhost:$lport:localhost:8384 hud@nemo sleep 300
        ec=$?
    fi

    if (( ec == 0 ))
    then
        printf '\n%s\n' "View remote syncthing gui at <http://localhost:$lport>"
    else
        echo "error occurred"
        echo "lsof -i :$lport says:"
        lsof -i :$lport
    fi
}
