_vscl_comp() {

    COMPREPLY=()
    # - Recall you can use COMP_WORDS, COMP_CWORD, and
    #   posn'l args are 1=cmd, 2=cur_wd, 3=prev_wd.
    local cur_wd prev_wd
    cur_wd=$2
    prev_wd=$3

    # Suggest known aliases if we are completing --proj=, or --proj [Tab], both of
    # which result in empty cur_wd, and prev_wd=--proj. Also if we have --proj=abc[Tab],
    # which causes cur_wd=abc and prev_wd='=', or --proj abc[Tab], which still has
    # prev_wd=--proj.

    if [[ $prev_wd == --proj ]] \
    || [[ $prev_wd == '='  && ${COMP_WORDS[COMP_CWORD-2]} == '--proj' ]]
    then
        # suggest project aliases if any
        local -A projs=()
        _vscl_aliases projs \
            || return

        local new_reply
        mapfile -t new_reply < \
            <( compgen -W "${!projs[*]}" -- "$cur_wd" )

        COMPREPLY+=( "${new_reply[@]}" )

    else
        # Use default code command completions
        # - pre-load completions
        _comp_load code

        # ensure completion spec has the expected form
        local cmp_spec
        cmp_spec=$( builtin complete -p code )

        [[ $cmp_spec == complete*"-F _code"* ]] \
            || { printf >&2 '%s\n' "unexpected cmp_spec"; return 9; }

        # call code completion func
        # - COMPREPLY will get any completions it finds
        set +u
        { _code "$@"; } \
            || echo 'proglems' >&2
        set -u

        # debug
        declare -p COMPREPLY

        # Augment COMPREPLY with new completions
        local new_reply=() poss_words=( --proj )
        mapfile -t new_reply < \
            <( compgen -W "${poss_words[*]}" -- "$cur_wd" )

        # debug
        declare -p new_reply

        COMPREPLY+=( "${new_reply[@]}" )
    fi

    return 0
}
complete -F "_vscl_comp" vsc vscn vscr
