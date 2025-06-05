st-gui() {
    : """start local syncthing GUI in browser"

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
	    { docsh -TD; return; }

    syncthing --browser-only
}
