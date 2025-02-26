# Google's Go language
[[ -d $HOME/gopath ]] && {
    export GOPATH=$HOME/gopath
    path_check_add -f "$GOPATH" "$GOPATH/bin"
}
