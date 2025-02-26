# file search and management with broot
[[ -n $( command -v broot ) ]] && {

    # Tips
    # - Ctrl-Right : focus (open) a preview panel to the right
    # - Enter : open a file using xdg-open, or make a dir the new root
    # - Alt-Enter : exit broot and open file, or cd to dir
    # - write selected path to stdout using :print_path (:pp)
    # - ideally, copy path would work using :copy_path, but it doesn't (yet)
    # - edit in terminal's EDITOR using :e, or open in vs-code using :vscn or :vscr

    [[ -d ${XDG_CONFIG_HOME:-~/.config}/broot/launcher/bash ]] && {

        # br() wrapper function
        # - starts broot and executes the command it produces, if any
        source ~/.config/broot/launcher/bash/br
    }

    # broot as file selector
    alias br-sel="br --conf ~/.config/broot/selector-config.toml"
}
