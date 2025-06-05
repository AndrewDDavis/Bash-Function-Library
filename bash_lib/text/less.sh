# less pager
# - maintained by [Nudelman](https://github.com/gwsw/less)

### Consider alternatives:
# - bat pager with syntax highlighting: https://github.com/sharkdp/bat
# - moar

### Less configuration for the keyboard shortcuts also occurs in the file at ~/.config/lesskey

### Interesting options:
#
#   -a : Search skips current screen to show next
#   -i : ignore case in search, unless it contains uppercase letters
#   -F : quit immediately if file fits on one screen
#   -j / --jump-target=n : target line is n lines (or fraction) from top
#   -J : show status column on the left (for search and marks)
#   -M : longer prompt including current line position
#   -N : show line numbers
#   -R : output ANSI colour sequences so the terminal renders them
#   -S : long lines are chopped (truncated) rather than wrapped
#   -w : highlight the first unread line after movement
#   -X : Disable termcap init/deinit (don't clear screen on return)
#   --buffers   : max RAM to allocate per file, in kB (default 64)
#   --incsearch : search as you type (tried this, found it counter-intuitive)
#   --line-num-width : min width of line no column (default 7)
#   --use-color : use colour in the interface; change them with --color=xab
#   --tabs      : multiple of cols for tab stops
#   --shift     : num. of cols to scroll with L/R arrow keys

# Set default options
# - note git uses -FRX if this is not set
export LESS="-iJMR --buffers=1024 --jump-target=.2 --tabs=4 --shift=4"

# Colours
if (( ${TERM_NCLRS:-2} >= 8 ))
then
    # - colour specs must be terminated with '$' in the LESS variable
    # LESS="$LESS --use-color --color=Pwk\$ --color=Ewy\$"
    # - vvv returning to default colours, not that I fixed terminal colour settings

    LESS="$LESS --use-color"
fi

# less search history file location
export LESSHISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}"/less/lesshst

# Important commands related to search:
#   Esc-u  : clear search highlighting
#   Esc-U  : clear search highlighting, search string, and status column marks
#   Ctrl-k : search but keep position
#   Ctrl-f : start search at first line of first file on cmd line
#   Ctrl-w : wrap search in current file
#   Ctrl-r : don't interpret regex metacharacters

# Editor called by less using the :v command
# default '%E ?lm+%lm. %g', where %E comes from VISUAL or EDITOR
[[ -n $( command -v micro ) ]] &&
    export LESSEDIT='micro ?lm+%lm. %g'

# Wrap text before input to less
# fmt -w $(tput cols) | less
# or
# fold -sw80 longlines.txt | less

lessx() {

    [[ $# -gt 0 && $1 =~ ^(-h|--help)$ ]] && {
        docsh -T """
        Run $(command -v less)
        # attempted to do limited line length, but it looked bad...

        Important Keybindings:
        h  : show help
        q  : exit
        r  : repaint screen
        F  : forward forever, like 'tail -f'
        ESC-F : like F but stop when search pattern is found
        <  : jump to start of file
        >  : jump to end of file
        [N]d : forward by half-window (or N lines and set half-window to N)
        [N]u : backward by half-window (or N as above)

        Navigation:
        Up/Down    : forward/backward by line
        Left/Right : scroll sideways by half-window (or to end with Ctrl-)
        PgDn/PgUp  : forward/backward by window
        """
        return 0
    }

    # will open file args if given, or accept stdin
    command less "$@"
}

# less handling of compressed files, e.g. gz and tar files, transparently
# - i think this script sometimes causes problems, and it's not well documented,
#   but it's handy when it works.
# - this is specifically the Debian lesspipe version, but there are others.
if [[ -x /usr/bin/lesspipe ]]
then
    lessz() {
        LESSOPEN="| /usr/bin/lesspipe %s"   \
        LESSCLOSE="/usr/bin/lesspipe %s %s" \
        less "$@"
    }
fi

if [[ -n $(command -v highlight) ]]
then

    less-hl() (

        [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

            docsh -TD """View source code in less with syntax highlighting

            Usage

            less-hl [opts] <file>

            -s <style> : set style (see note below)
            -O <fmt>   : ansi, truecolor, or xterm256

            - last arg is filename ('-' may work for stdin)
            - other args are options for less (use -- first)

            Notes

            - To show config dirs and styles (themes), use:
                highlight --list-scripts=themes
            - Recommended:
                + github with truecolor (light BG)
                + bright with xterm256 (light BG)
            - When using ansi output format, there is only 1 (hard-coded)
                colour theme.
            """
            return 0
        }

        # parse args
        local hl_style hl_outfmt
        local OPT OPTARG OPTIND=1

        while getopts "s:O:" OPT
        do
            case $OPT in
              (s) hl_style=$OPTARG ;;
              (O) hl_outfmt=$OPTARG ;;
            esac
        done
        shift $((OPTIND - 1))

        # get filename and options from command line
        local fn less_opts hl_opts

        fn=${@:(-1):1}

        less_opts=( "${@:1:$#-1}" )
        less_opts+=( -R )

        hl_opts=()

        # TODO:
        # - try styles with dark BG

        # syntax from glob
        if [[ $fn == *.md.txt ]]
        then
            hl_opts+=( "--syntax=markdown" )
        fi

        # output format
        hl_opts+=( -O "${hl_outfmt:-xterm256}" )

        # style
        if array_match hl_opts xterm256
        then
            hl_opts+=( -s "${hl_style:-bright}" )

        elif array_match hl_opts truecolor
        then
            hl_opts+=( -s "${hl_style:-github}" )
        fi

        (
            set -x
            less "${less_opts[@]}" < <(highlight "${hl_opts[@]}" "$fn")
        )
    )
fi
