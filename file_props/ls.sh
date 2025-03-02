# Aliases, functions, and environment for ls

## Notable ls options
#
#  -A   : include dot files, except . and ..
#  -d   : do not recurse directories on command line
#  -L   : dereference symlinks
#  -R   : recurse subdirectories
#
#  -l   : show details (permissions, times, sizes)
#  -1   : show as a column, without the details of -l
#  -w X : limit terminal width used to print output (BSD ls used COLUMNS instead)
#  -C   : output in columns (subject to width)
#  -s   : print disk size allocated for each file (matches 'total' from -l; use with -1)
#  -n   : like -l, but use numeric uid and gid
#
#  -F   : append file-type chars to names
#  -h   : if sizes are shown, they get 'human-readable' suffixes
#  -p   : append '/' to dir-names
#  -Q   : double-quote file names, and use C-style escapes (see --quoting-style)
#
#  -r   : reverse sort order
#  -t   : sort by time
#  -v   : sort by 'version' (e.g. abc10 after abc9, but also Bbc before abc)

## Colourized output and sorting order (collation)
#
# If LC_COLLATE is set to C, capitalized words will sort before lower-case. If this is
# not desired, you can use e.g. "LC_COLLATE=$LANG" before an ls command on Linux.
# However, the LANG variants like en_CA and en_US ignore punctuation, making dotfiles
# sort into the other results, which I don't like. See further discussion in Locales
# notes. In addition, macOS doesn't seem to use the collation strings properly since
# the introduction of APFS... you need my 'sort-noansi' function there, like:
# ls -1 --color | sort-noansi -f

# - aliases defined for other commands will also apply, e.g. 'll -> ls --color -l'
realias ls "LC_COLLATE=C.utf8 ls"

## Platform specific options

if ls --version 2>/dev/null | grep -q 'GNU'
then
    # GNU ls

    alias lw="ls -xp -w76"
    alias lc="ls -Cp -w76"
    alias lw-dir="lw --group-directories-first"      # also applies to symlinked dirs
    alias ls-sort="ls -p1 --color | sort-noansi -f"

    if [[ ${_term_n_colors:-2} -ge 8 ]]
    then
        # colours
        realias ls "ls --color=auto"

        # - dircolors sets and exports the LS_COLORS env var
        # - prefer my custom file, otherwise ~/.dircolors
        if [[ -n $( command -v dircolors ) ]]
        then
            if [[ -n $( command -v set_lscolors )
                && -e ${XDG_CONFIG_HOME:-~/.config}/lscolors/dircolors.combined ]]
            then
                set_lscolors

            elif [[ -e ~/.dircolors ]]
            then
                eval $( dircolors -b ~/.dircolors )

            else
                eval $( dircolors -b )
            fi
        fi
    fi

elif [[ ${_term_n_colors:-2} -ge 8 ]] && ls -G &> /dev/null
then
    # BSD ls

    alias lw="COLUMNS=76 ls -xp"
    alias lc="COLUMNS=76 ls -Cp"
    alias ls-sort="CLICOLOR_FORCE=1 ls -p1 | sort-noansi -f"

    # - relies on LSCOLORS, see format in man ls
    #   default is 'exfxcxdxbxegedabagacad'
    # - alias ls='ls -G' is redundant when CLICOLOR is set
    # - color still disabled for non-terminal output (pipes etc.),
    #   unless CLICOLOR_FORCE is set
    export CLICOLOR=1

    [[ -n $(command -v gls) ]] && {
        # for GNU ls on macOS
        realias gls "LC_COLLATE=C.utf8 gls --color=auto"
    }
fi

# long form
alias ll="ls -lhp"
alias ll-dot="ls-dot --use_alias=ll"

alias lla="ll -A"
alias lld="ll -d"
alias llrt="ll -rt"

# limited width, written across
alias lwa="lw -A"
alias lwd="lw -d"
alias lw-dot="ls-dot --use_alias=lw"

# columns with limited width
alias lca="lc -A"
alias lcd="lc -d"
alias lc-dot="ls-dot --use_alias=lc"

# single column
alias l1="ls -1p"
alias l1a="l1 -A"
alias l1d="l1 -d"

# a glob to match dot-files, but not . and ..
# - NB this is unnecessary in bash with 'globskipdots' enabled (the default)
#_dotglob='.[^.]* ..?*'
