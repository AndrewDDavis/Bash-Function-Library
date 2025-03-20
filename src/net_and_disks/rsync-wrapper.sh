alias rsync="rsync-wrapper"
alias rsync-local='rsync-wrapper --local-copy'
alias rsync-check='rsync-wrapper --local-diff'

rsync-wrapper() {

    :  "Wrapper function for rsync with useful modes

        This function uses the merge-files syntax of --filter to apply the rules found
        in ~/.config/rsync/default.rules. This is intended to exclude annoying files
        from interactive rsync transfers.

        To clear the include/exclude list, the syntax is: -f'!'.

        Another way to exclude files according to a ruleset is -F, which uses per-dir
        files, e.g. --filter=': /.rsync-filter'. To exclude files in a one-off fashion,
        use --exclude=PATTERN.

        This function generally passes all of its arguments unchanged to rsync, but
        has these additional flags for specific modes:

          --local-copy
          : Set good defaults for copying local files. This sets:
            -ivh --stats -rlD -pAgo -tU -XH

          --local-diff
          : Check for differences among local files. In addition to the options of
            local-copy, adds: -nc --delete.

          --rsbak
          : Create backup files, using the options:
            --backup --suffix='.rsbak'
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local rs_cmd rs_args
    rs_cmd=$( builtin type -P rsync ) \
        || return 5

    [[ -r ~/.config/rsync/default.rules ]] &&
        rs_args+=( -f ". ${HOME}/.config/rsync/default.rules" )

    local loc_args=( -ivh --stats -rlD -pAgo -tU -XH )

    case $1 in
        ( --local-copy )
            # - my rsync on Debian testing doesn't have -N
            rs_args+=( "${loc_args[@]}" )
            shift
        ;;
        ( --local-diff )
            rs_args+=( "${loc_args[@]}" -nc --delete )
            shift
        ;;
        ( --rsbak )
            rs_args+=( --backup --suffix='.rsbak' )
            shift
        ;;
    esac

    "$rs_cmd" "${rs_args[@]}" "$@"
}
