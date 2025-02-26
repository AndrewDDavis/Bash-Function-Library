# nnn (n3) file manager
# - no config file, only env? see man page with options

if [[ -n $(command -v nnn) ]]
then
    # defaults: detail, text editor, version sort
    alias nnn='nnn -de -T v'

    # use Trash (instead of rm -rf): 1=trash-cli, 2=gio trash
    export NNN_TRASH=1

    # custom sort orders
    export NNN_ORDER='t:/home/andrew/Downloads'

    # plugins
    export NNN_PLUG

    _nparr=( 'v:-!&code "$nnn"*' )

    # - clipboard copy
    [[ -n $(command -v wl-copy) ]] && {
        _nparr+=( 'b:-!echo "$nnn" | wl-copy*' )
        _nparr+=( 'p:-!echo "$PWD/$nnn" | wl-copy*' )
    }

    for _np in "${_nparr[@]}"
    do
        # add semicolon and new plugin
        NNN_PLUG="${NNN_PLUG:+$NNN_PLUG;}${_np}"
    done
    unset _np _nparr

    # cppath not working; fork and fix?
    #[[ -f ~/.config/nnn/plugins/cppath ]] && export NNN_PLUG="${NNN_PLUG}c:cppath;"

    #export NNN_SSHFS='sshfs -o reconnect,idmap=user,cache_timeout=3600,transform_symlinks'
fi
