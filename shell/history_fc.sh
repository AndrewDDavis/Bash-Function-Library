# Shell Command History

# TODO:
# - split up the bashrc parts of this and the functions that are intended
#   for interactive use.

## History size

# In a default bash shell, the following variables are set (but not exported to the environment):
# - HISTFILE=~/.bash_history
# - HISTSIZE=500
# - HISTFILESIZE=500
#
# - NB, can get a default shell with e.g.
#   `env -i TERM=$TERM sudo -u andrew bash --norc`.

# - Setting a large HISTSIZE uses more RAM and may slow down logins over network.
# - To see the interaction btw HISTSIZE and HISTFILESIZE values, see [examples
#   in this answer](https://stackoverflow.com/a/19454838/1329892)
export HISTSIZE=10000        # lines to retrieve/save each session
export HISTFILESIZE=2400000  # max no. of lines for 64MB file @ 28B/line


## Shell options

# The following options are set by default in interactive shells:
# - history : turn on command history features (don't set it here, or this script's commands
#   would be added to history).
# - cmdhist : save multi-line commands as a single line with ';'
# - histexpand : substitute commands from history with '!'
# - lithist : embed newlines instead of ';' when cmdhist is set; I tested this, but it messes
#   up multiline commands in the history written to disk.

# - I like to turn off histexpand, as it's hard to use and gives '!' special meaning, which
#   can be unexpected. It was needed for my 'alt-w' (retype-last-word) macro defined
#   in .inputrc, but now I use the rl_retype_word function bound with 'bind -x'.
# - Readline keybindings to the history are more useful than ! IMO, and my hist-grep
#   and rx functions. Also see the fc built-in and aliases.
# - When actually using histexpand, it seems reasonable to turn on histverify too.
set +o histexpand
shopt -s histverify  # verify history substitutions before executing (can also use \e^)
shopt -s histreedit  # reload failed history substitutions


## Append to history

if [[ ${TERM_PROGRAM:-} == Apple_Terminal ]]
then
    true

    # - Apple Terminal.app has its own, more sophisticated, way of implementing both
    #   session-specific history recovery for Terminal, and blended history retrieval
    #   of closed sessions history for new sessions, in /etc/bashrc_Apple_Terminal
    #   (sourced from /etc/bashrc). This is implemented in ~/.bash_sessions, and
    #   applied as long as the following conditions are met:
    #   - SHELL_SESSION_HISTORY is not 0
    #   - HISTTIMEFORMAT is not defined
    #   - histappend is not set
    #   - ~/.bash_sessions_disable does not exist (disables the save/restore mechanism)

else
    # Define HISTTIMEFORMAT so history lines get a timestamp
    # - note time is recorded in seconds from epoch; HTF only controls the display, and
    #   whether or not it is recorded at all
    # - '%F %R' uses ISO date and Hr:Min; I also like '%Y-%j', which is ISO year
    #   followed by day of year (1-366), or '%G-%V-%u' or '%G-%U-%w', which is ISO week-based
    #   year, followed by week number, then day of week (0-6 or 1-7, with 0=Sunday).
    HISTTIMEFORMAT='%F %R  '

    # Consider something like bash_eternal_history:
    # PROMPT_COMMAND+=( 'echo $$ $USER "$(history 1)" >> ~/.bash_eternal_history' )

    # Save session history in e.g. ~/.bash_history.d/bash_sess_$HOSTNAME_$BASHPID


    # Append to history after every command, so new shells get recent history
    # - preserves prev PROMPT_COMMAND; if it was string, converts to array, but prevents
    #   adding repeated 'history -a' if .bashrc is sourced again after edits.
    if [[ ! -v PROMPT_COMMAND[@] ]] || ! array_match PROMPT_COMMAND "history -a"
    then
        PROMPT_COMMAND+=( "history -a" )
    fi

    # Setting a non-default file name is recommended, so e.g. `screen` doesn't truncate
    # using default size settings, but macOS uses ~/.bash_history anyway.
    # - should be symlinked to sth like ~/.bash_history.d/bash_extended_history-${HOSTNAME}
    export HISTFILE=~/.bash_extended_history

    # On shell exit, append new history lines to the history file instead of overwriting
    shopt -s histappend
fi


## HISTCONTROL
#
# A colon-separated list of keys controlling how commands are saved to the history list.
#
# - ignorespace : don't add lines beginning with space to the history list
# - ignoredups  : lines matching the previous history entry are not saved
# - ignoreboth  : ignorespace + ignoredups
# - erasedups   : all previous lines matching the current line are removed from the
#                 history list before that line is saved
#
# The functionality of erasedups will be used before saving to disk in the code below.
#export HISTCONTROL='ignorespace:erasedups'
export HISTCONTROL='ignoreboth'

## HISTIGNORE
#
# A colon-separated list of patterns used to decide which command lines should be saved on
# the history list.
#
# - Patterns are anchored at the beginning of the line, and must match the complete
#   line, including pipes etc. So adding 'ls' excludes lines that are ls alone, but
#   'ls *' would be needed to match all lines starting with the ls command.
# - '&' matches the previous history line.
# - See 'man bash' for further details.
# - NB, this excludes commands from the in-memory history list, so e.g. hitting the up
#   arrow shows the command before the one in this list; I would rather have a solution
#   keeps the current session history intact, but excludes some commands from saving to disk.
#HISTIGNORE='ls:ll:cd:pwd:bg:fg:declare -p *:history:hist-grep *'
#HISTIGNORE="ls:ls -l:ll:l1:lw:l:cd:pwd:bg:fg"



# - TODO: would be nice to set the history up so that the commands of the current
#   session all remain in order, but the history file only gets unique command
#   lines
# see draft function: https://unix.stackexchange.com/a/210300/85414
#
# Ideal history handling:
# - History within a session is preserved
# - History file is constantaly updated, so new shells get the most recent commands
# - On closing, session history is cleansed of mundane commands like echo, ls, ll, l1, cat, wc,
#   head, tail, man, tree, type, export, declare, decp, ...
# - Should contain function defns, as they're usually only 1 line, and they're searchable.
# - In the file, history gets re-organized by session-ID. To get a unique value for the
#   session ID, consider the date it was started: date -d "$(ps -p $$ -o lstart=)" '+%F
#   %R' on Linux, or on macOS date -j -f "%c" "$(ps -p $$ -o lstart=)" "+%F %R"

# TODO:
# - Something like this, to clean commands from the file that are beyond HISTSIZE/2, or
#   at least multi-word commands that only differ in the last argument.
HISTCLEANFILE="cd *:man *:help *:helpm *:ls *:ll *:lld *:echo *"



# The built-in commands are 'fc' and 'history'. Consider 3rd party tools:
# - atuinsh
# - mcfly
# - fzf

# fc
alias fce="fc"
alias fcl="fc -l"
alias fcs="fc -s"
alias fcx="rx"

rx() {
    local docstr="Re-execute lines from history

    The 'fc' builtin is used to display or re-execute commands from the history
    list. This function is an alias to 'fc -s', which re-executes commands
    using this form:

        rx [pat=rep] [cmd]

        'cmd' : may be an integer, representing a history line, or a string
                that selects the most recent command starting with those
                characters. If a negative integer is given, it is interpreted
                as an offset from the present command.

        'pat' : in the selected command line, each instance of 'pat' is
                replaced by 'rep'.

    If 'pat' is not used, the selected command is rerun without changes, so that
    'rx abc' reruns the last command starting with 'abc'. The default for 'cmd'
    is -1, so that 'rx' alone reruns the previous command.

    To list commands, use 'fc -l', as:

        fc -l [-nr] [first] [last]

        -n : omit command numbers in listing output.
        -r : reverse the command listing order.

    To open a list of commands in an editor, then run the saved list of
    commands, use:

        fc [-e ename] [-r] [first] [last]

        -e : select editor to use, by default FCEDIT, EDITOR, or vi.
        -r : reverse command listing order.

    The arguments 'first' and 'last' define a series of commands in the history
    list. They may each be a number or a string, and are interpreted in the
    same way as 'cmd' above. The default for first is -16 when listing, so that
    'fc -l' is very similar to running 'history 15'. The default is -1 when
    editing, so running 'fc' alone allows editing of the previous command line.
    To cancel running any commands when in editing mode, clear the file and
    save it.

    Usage:

      # rerun the previous command
      rx

      # rerun the 3rd-last command
      rx -3

      # rerun the last man command
      rx man

      # list the last 10 commands
      fc -l -10

      # list 5 commands starting from 25 commands back
      fc -l -25 -21

      # list the commands since man was last run
      fc -l man

      # list the most recent commands from man to echo, inclusive
      fc -l man echo

      # edit a list of the last 5 commands, then run the saved list
      fc -5
    "

    [[ $# -gt 0 && $1 =~ ^(-h|--?help)$ ]] && {

        docsh -TD "$docstr"
        return 0
    }

    fc -s "$@"
}

hist-grep() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Search the history files for occurrences of a pattern.

        The \`egrep\` command is used for searching, and the glob for history files
        is \`~/.bash*history\`.
        "
        return 0
    }

    local hfn grep_out rxc

    for hfn in ~/.bash*history
    do
        if grep_out=$( egrep "$@" "$hfn" )
        then
            # report history filename
            printf '\n%s:\n\n' "${_cul:-}${hfn}${_cru:-}"

            # regex to match commands
            rxc='((sudo|export|local|declare|typeset)[ ]+(-[^ ]+[ ]+)?)?[^ =]+=?'

            # search, then filter output
            printf '%s\n\n' "$grep_out" |
                sed -E "# remove file name
                        s|^${hfn}:||

                        # remove hist-grep commands?
                        /^hist-grep.*/ d

                        # give commands bold styling
                        s/^($rxc)/${_cbo:-}\1${_crb:-}/

                        # also apply to commands following | or ;
                        s/ (\||;) ($rxc)/ \1 ${_cbo:-}\2${_crb:-}/g

                       "
        fi
    done
}
