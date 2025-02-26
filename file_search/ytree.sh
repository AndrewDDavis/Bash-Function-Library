# ytree: classic TUI file manager
[[ -n $(command -v ytree) ]] && {

    yt() {
        # wrapper function to cd on exit
        # - usage: ytree [archive file|directory], then
        #          exit with ^Q

        mkdir -p ~/.cache
        local yt_file=~/.cache/ytree-$$.chdir

        printf '%s\n' "cd $PWD" > "$yt_file"

        if command ytree "$@"
        then
            local yt_cmd=$( < "$yt_file" )
            command rm -f "$yt_file"

            eval "$yt_cmd"

        else
            local yt_code=$?
            command rm -f "$yt_file"

            return "$yt_code"
        fi
    }
}

