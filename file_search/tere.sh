tere() {
    docstr="Use tere to navigate, then cd to the chosen dir
    
    Tere is a TUI file explorer. For command usage, run 'command tere --help'
    "
    
    [[ $1 =~ ^(-h|--?help)$ ]] && {
    
        docsh -TD "$docstr"
        return 0
    }
    
    local tere_dir
    
    if tere_dir=$(command tere "$@")
    then   
        [[ -n $tere_dir ]] && cd -- "$result"
    fi
}

