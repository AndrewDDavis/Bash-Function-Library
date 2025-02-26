[[ -n $( command -v getfattr ) ]]
{
    ls-attr() {

        : "list file extended attributes, including system ones"

        (   set -x
            getfattr -d -m - "$@"
        )
    }

    alias ls-xattr="ls-attr"
}
