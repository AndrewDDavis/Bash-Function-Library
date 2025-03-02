# Use canonical (physical) path for cd by default
# - safer, as it matches e.g. `ls ../` from a symlink dir
# - see https://unix.stackexchange.com/a/413225/85414
#alias cd="builtin cd -P"
# - set the option instead, so it applies to pushd too
shopt -so physical

# Search path for cd
# - ultimately I found this more annoying than useful
#export CDPATH=".:~:~/Sync:~/Media:~/Documents"

# - Consider also setting cdable_vars; then a var that holds a directory
#   name can be used as an argument to cd, without typing '$', E.g.:
#   shopt -s cdable_vars
#   d1=foo
#   cd d1   # shell cd's to foo

# dirs stack
alias dv="dirs -v"

# add a few defaults to the stack
pushd -n ~/Sync >/dev/null
pushd -n ~/Documents >/dev/null

cd() {

    [[ ${1:-} == @(-h|--help) ]] &&
    {
        docsh -TD "Change dirs with cd, but also keep track on the dir-stack

        Usage: $FUNCNAME [cd-opts] [dir]

        Unlike when using \`pushd\`, calling the \`cd\` command only changes top element of
        the dirs stack, visible through PWD or \`dirs +0\`, and doesn't otherwise interact
        with the dirs stack. For \`cd\`, the previous dir is tracked using the OLDPWD
        variable to allow going back with \`cd -\`. This wrapper function adds PWD to the
        dirs stack using pushd before calling cd using the arguments.

        Using the dirs list (or dir-stack):

          dirs -v
          : print numbered dirs list. The DIRSTACK variable holds the list, but pushd and
            popd should be used to add and remove items.

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
          : exchange top 2 dirs of the stack

          pushd +N
          : cd to Nth dir, then rotate the stack so it's on top

          popd (or popd +0)
          : remove CWD from the list and cd to the dir at position +1
        "
        return 0
    }

    # Push current dir onto the stack (quietly)
    pushd -n "$PWD" >/dev/null

    # If path (from last arg) is relative and exists, prepend ./ to avoid the message due
    # to matching against CDPATH
    [[ $# -gt 0  &&  -d ${@:(-1)}  &&  ${@:(-1)} =~ ^\.?[a-zA-Z0-9] ]] &&
    {
        # debug
        #echo set -- "${@:1:$(($#-1))}" ./"${@:(-1)}"

        set -- "${@:1:$(($#-1))}" ./"${@:(-1)}"
    }

    # call cd (shell builtin)
    builtin cd "$@"
}
