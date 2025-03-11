# file search and launch with fzf
[[ -n $(command -v fzf) ]] && {

    fzf-find() {
        find "$@" -print | fzf
    }

    fzf-loc() {
        locate -ib "$@" | fzf
    }

    # browse text files with fzf and open them in less, etc.
    fzf-less() {
        fzf --bind "enter:execute(less {})"
    }

    fzf-gedit() {
        fzf --bind "enter:execute(gedit {})"
    }

    fzf-vscr() {
        fzf --bind "enter:execute(vscr {})"
    }
}
