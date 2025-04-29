_scw_comp() {

    COMPREPLY=()

    # pre-load completions function
    _comp_load "systemctl"

    # ensure completion spec has the expected form
    local cmp_spec
    cmp_spec=$( builtin complete -p "systemctl" )

    [[ $cmp_spec == complete*"-F _systemctl"* ]] \
        || return 9

    # call parent completion func
    # - COMPREPLY will get any completions it finds
    "_systemctl" "$@"

    # Augment COMPREPLY with new completions below
    # - this is pretty basic, but workable for a wrapper function
    local cur prev new_reply
    cur=$2
    prev=$3

    local ctx_words=( -u -s -r -g )
    local cmd_words=( lsu lsu-all lsf find lst )

    if [[ $COMP_CWORD == 1 ]]
    then
        # first arg after scw: context option or command (or alias)
        mapfile -t new_reply < \
            <( compgen -o nosort -W "${ctx_words[*]} ${cmd_words[*]}" -- "$cur" )

        COMPREPLY=( "${new_reply[@]}" "${COMPREPLY[@]}" )

    elif [[ $COMP_CWORD == 2  && $prev == -* ]]
    then
        # still need a command (or alias)
        mapfile -t new_reply < \
            <( compgen -o nosort -W "${cmd_words[*]}" -- "$cur" )

        COMPREPLY=( "${new_reply[@]}" "${COMPREPLY[@]}" )
    fi

    return 0
}
complete -o nosort -F "_scw_comp" "scw"
