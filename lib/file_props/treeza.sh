# convenient aliases
# alias tt="treeza"
# alias ta="treeza -a"
# alias tl="treeza -lo --no-permissions"
# alias tla="treeza -alo --no-permissions"

treeza() {

    : "Tree view of CWD using eza

        Recommended options:

          -L
          -lo --no-permissions

        Colours: using a plain theme file to disable the christmas tree for -l view:
                 ~/.config/eza/theme.yml
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
