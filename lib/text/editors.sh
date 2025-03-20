# Text Editors

### Nano text editor
# - see /etc/nanorc and ~/.config/nano/
# - note, there is no special bash-completion for nano

# modern keybindings by default (new in 8.0)
alias nano='nano --modernbindings'

# nano as a viewer (read-only mode)
alias nanov='nano -v'


## micro editor
# - turn on truecolor support
[[ -n $(command -v micro) ]] && {
    [[ ${COLORTERM:-} == truecolor ]] && export MICRO_TRUECOLOR=1
}

## textadept editor
[[ -n $(command -v textadept) ]] && {
    alias ta="textadept"
    alias ta-c="textadept-curses"
    alias ta-g="textadept-gtk"
}

# Sublime Text
[[ -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ]] && {
    alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
}


# Pragtical Editor
if [[ -n $( command -v pragtical ) ]]
then
    # alias for ppm: pragtical package manager
    alias ppm='pragtical pm'

    # run the integrated terminal as standalone
    # - see https://github.com/pragtical/terminal
    prag-term() {

        # write this somewhat legibly
        local pt_config='config.plugins.treeview=false
                         config.plugins.workspace=false
                         config.always_show_tabs=false
                         local _,_,x,y = system.get_window_size()
                         system.set_window_size(800, 500, x, y)
                         local TerminalView = require "plugins.terminal".class
                         local old_close = TerminalView.close
                         function TerminalView:close()
                            old_close(self)
                            os.exit(0)
                         end
                         core.add_thread(function() command.perform("terminal:open-tab")
                                            local node = core.root_view.root_node:get_node_for_view(core.status_view)
                                                         node:close_view(core.root_view.root_node, core.status_view)
                                         end)'

        # remove newlines and tabs, and squeeze spaces to match the line in docs
        pt_config=$( tr '\n\t' ' ' <<< "$pt_config" | tr -s ' ' )

        PRAGTICAL_SCALE=1.75 ppm run terminal --config "$pt_config"
    }
fi
