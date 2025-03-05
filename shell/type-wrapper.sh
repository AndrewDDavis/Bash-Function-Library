type-aF() {

    [[ $# == 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Print command type, suppressing function definitions.

        Usage: type-aF [args for \`type -a\`] <command-name> ...

        type-aF runs \`type -a\` on all arguments, which indicates how each
        command name would be interpreted (e.g. executable, shell function, builtin,
        etc.). The output is passed through a \`sed\` filter, which suppresses printing
        of the function definitions.
        "
        return 0
    }

    type -a "$@" |
        sed '/ is a function$/ {
                 p
                 # start "loop": terminates on closing brace
                 : fn
                     # using N, because n would print
                     N
                     # strip previous line from pattern
                     s/^.*\n//
                     # if line is just a closing brace, filter is finished
                     /^}$/ d
                 # otherwise, loop to check the next line
                 b fn
             }'
}
