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
    local cur prev
    cur=$2
    prev=$3
    # context words
    if [[ ]]

    # augmented command words
    # local canditate_words="--foo"
    # COMPREPLY+=( $( compgen -W "$canditate_words" -- "$cur" ) )

    return 0
}
complete -F "_scw_comp" "scw"
