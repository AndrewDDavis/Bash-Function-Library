# VS-Code editor

# aliases to open in a re-used window or a new window
alias vscr='vsc-launcher -r'
alias vscn='vsc-launcher -n'

# aliases to open commonly used projects
# - add project folders to the function's array below
alias vsc-bread='vscn --proj=bread'
alias vsc-food='vscn --proj=food'

vsc-launcher() {

    : "Quick aliases to open commonly-used VS-Code projects

        Usage: vscode-wrapper [--proj=word] [vs-code arguments ...]

        All arguments other than --proj=word are passed to the code command. Refer to
        the docs of that command using 'code --help'.

        Examples

          # open the 'bread' project directory in a new window
          vscode-launcher -n --proj=bread
    "

	[[ $# -eq 0  || $1 == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    # define paths for commonly-used projects
    local -A projs=()

    projs["bread"]="$HOME/Documents/Food and Diet/Bread"
    projs["food"]="$HOME/Documents/Food and Diet"

    # vs-code command path
    local vsc_cmd
    vsc_cmd=$( builtin type -P code ) \
        || return 9

    # check for --proj arguments
    local a i=1 j k
    for a in "$@"
    do
        if [[ $a == --proj=* ]]
        then
            # make a valid vs-code command line using the project path
            a=${a#'--proj='}
            [[ -v "projs[$a]" ]] \
                || { err_msg 3 "project not found: '$a'"; return; }

            j=$((i-1))
            k=$((i+1))
            set -- "${@:1:j}" "${@:k}" "${projs[$a]}"
        fi
        (( ++i ))
    done

    "$vsc_cmd" "$@"
}
