# Text file filtering and search with grep
#
# - For functions using 'grep -r' to search for matching files, see the
#   '../file_search' dir.

# Colourized output
if  [[ ${_term_n_colors:-2} -ge 8 ]] &&
    grep --color=auto . <<< test_string &>/dev/null
then
    # GNU and BSD grep
    # - relies on GREP_COLOR or GREP_COLORS
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # GNU grep and ugrep colours
    # - refer:
    #   https://github.com/Genivia/ugrep?tab=readme-ov-file#color
    #   https://www.gnu.org/software/grep/manual/grep.html#Environment-Variables
    # - specify 256-color codes with 38;5;x, x E [0,255]
    # - enforce GNU grep defaults in both:
    #export GREP_COLORS='sl=:cx=:mt=01;31:fn=35:ln=32:bn=32:cn=32:se=36'
    # - bold matched text, underline filenames, dim context, metadata gets white background
    export GREP_COLORS='sl=:cx=3:mt=1:fn=4;35;107:ln=107:bn=107:cn=107:se=2;107'
fi

# Case insensitive grep variants
alias grepi="grep -i"
alias egrepi="grep -iE"
alias fgrepi="grep -iF"
