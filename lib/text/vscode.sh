# VS-Code editor

# - aliases to open in a re-used window or a new window
alias vscr='code -r'
alias vscn='code -n'

vscn-fzf()
{
    # use fzf to choose a file for vs-code to open
    builtin cd ~/Sync/Documents
    code -n "$( fzf )"
}

vsc-food()
{
    # open the food dir in a new vs-code window
    code -n ~/Documents/"Food and Diet" &
}

vsc-bread()
{
    # open the food dir in a new vs-code window
    code -n ~/Documents/"Food and Diet/Bread" &
}
