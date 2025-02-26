# lf file manager

lfcd () {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

	    docsh -TD "Change shell working dir using lf

        You may also like to assign a key (e.g. Ctrl-O) to this command:

          bind '"\C-o":"lfcd\C-m"'  # bash
          bindkey -s '^o' 'lfcd\n'  # zsh
	    "
	    return 0
    }

    local _lfwd
    # `command` is needed in case `lfcd` is aliased to `lf`

    if _lfwd=$( command lf -print-last-dir "$@" )
    then
        cd "$_lfwd"
    fi
}
