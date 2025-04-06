# convenient aliases
# - NB, eza prints human-readable sizes with -l
alias tt="treeza -L2"
alias tta="tt -a"
alias ttd="tt --only-dirs"
alias ttl="tt -lo --no-permissions"
alias ttad="tt -a --only-dirs"
alias ttal="tt -alo --no-permissions"

treeza() {

    : "Tree view of CWD using eza

        Runs eza --tree --group-directories-last, with a custom time-style and using
        -I '**/.git' to ignore git directories.

        This source file also adds 'tt' aliases to treeza for convenience, which run
        'treeza -L2' by default, or tta which adds the -a option, ttd which adds
        --only-dirs, ttl which adds -lo --no-permissions, or combinations thereof.

        Refer to the eza manpage for explanations of the options.

        It is recommended to use a theme file that sets more plain colours to disable
        the distracting christmas tree that eze outputs by default with -l. This file
        is located at '~/.config/eza/theme.yml'.
    "

    local eza_cmd
    eza_cmd=( "$( builtin type -P eza )" ) \
        || return 9

    # tree
    eza_cmd+=( --tree --group-directories-last )

    # time format:
    # - multi-line string, non-recent files get ISO date, recent files get month-day hour:min
    eza_cmd+=( --time-style=$'+%Y-%m-%d\n%m-%d %H:%M' )

    # ignore git dir (can't do just contents, nor add trailing slash, for now; may be a fix coming)
    eza_cmd+=( -I '**/.git' )

    "${eza_cmd[@]}" "$@"
}
