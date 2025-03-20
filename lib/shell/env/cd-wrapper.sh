alias cd='cd-wrapper'

cd-wrapper() {

    [[ ${1-} == @(-h|--help) ]] && {

        : "Change the working directory and update the directory stack

        Usage

          cd-wrapper [-L|-P] [dir]
          cd-wrapper (+|-)N

        This wrapper function calls the pushd built-in command to change the current
        working diretory (CWD), rather than cd, so that the directory stack is updated
        during interactive use.

        Unlike when using \`pushd\`, the \`cd\` built-in command only changes top
        element of the directory stack, visible through PWD or \`dirs +0\`. The \`cd\`
        command does track the previous PWD value using OLDPWD, which is available
        using the \`cd -\` command.

        This function supports the -L and -P options of the cd command to explicity
        use the physical path, or allow a path with symlinks, regardless of the status
        of the 'physical' shell option. This allows paths like 'cd -P l1/..' to be
        interpreted as expected. Refer to the docs of the phys_dirpath and _shrtn_cwd
        functions for more details.

        This function allows the pushd notation '+N' to specify a directory from the
        stack. The stack may be shown using 'dirs -v', which may be aliased to 'dv'.

        The directory stack is also visible as the DIRSTACK array variable. The entries
        other than [0] may be manipulated manually, but pushd and popd must be used to
        add and remove items.

        Builtin commands to interact with the directory stack

          dirs -v
          : print the directory stack as a numbered column

          dirs +N
          : print nth most recent dir (current is +0)

          dirs -N
          : print nth dir from the end (oldest is -0)

          dirs -c
          : clear the list

          pushd dir
          : add dir to dir-stack, cd to it, and run dirs to show the stack

          pushd -n dir
          : only add dir at position +1, don't cd

          pushd
          : exchange top 2 dirs of the stack; the former +1 dir will be the new CWD

          pushd +N
          : rotate the stack so the Nth dir is on top, then cd to it

          popd (or popd +0)
          : remove CWD from the list and cd to the dir at position +1

          popd +N
          : remove the Nth dir from the stack
        "
        docsh -TD
        return
    }

    # handle cd options
    local _L _P cd_cmd=( builtin cd )

    local flag OPTARG OPTIND=1
    while getopts ':LP' flag
    do
        case $flag in
            ( L | P ) cd_cmd+=( "-$flag" ) ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    local tgt_dir

    if [[ $# -eq 1  && $1 =~ ^(\+|-)[0-9]+$ ]]
    then
        # +N/-N are sent straight to pushd
        [[ -v _P  || -v _L ]] &&
            { err_msg 5 '-L and -P not supported with +/-N'; return; }
        tgt_dir=$1
    else
        # use cd to get the physical version of the intended dir
        # - take care of cd return status
        tgt_dir=$(
            "${cd_cmd[@]}" "$@" >/dev/null \
                || exit
            builtin pwd -P
        ) \
            || return
    fi

    pushd "$tgt_dir" >/dev/null

    # vvv OLD way

#     # Push current dir onto the stack (quietly)
#     pushd -n "$PWD" >/dev/null
#
#     # If path (from last arg) is relative and exists, prepend ./ to avoid the message due
#     # to matching against CDPATH
#     [[ $# -gt 0  && -d ${@:(-1)}  && ${@:(-1)} =~ ^\.?[a-zA-Z0-9] ]] &&
#     {
#         # debug
#         #echo set -- "${@:1:$(($#-1))}" ./"${@:(-1)}"
#
#         set -- "${@:1:$(($#-1))}" ./"${@:(-1)}"
#     }
#
#     # call shell builtin command cd
#     builtin cd "$@"
}
