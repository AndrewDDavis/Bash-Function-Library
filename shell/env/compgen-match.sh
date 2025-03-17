compgen-match() {

    [[ $# == 0  ||  $1 == @(-h|--help) ]] && {

        : "List shell features and definitions using compgen.

        compgen-match is a wrapper function for \`compgen\` that's meant to be used
        with the aliases defined in this file. The aliases based on the list of
        available compgen "actions" to generate completions, which is available in
        \`man bash\`, in the section on the \`complete\` builtin. Alternatively, the
        list of actions can be generated using \`compgen -A [Tab]\`.

        The return status is 0, unless there were no matches for the completion.

        Usage

          compgen-match <action> [string]

        The optional string argument is taken as the start of a completion operation,
        so that matches starting with the string are displayed. Of course, the listed
        output can also be parsed with grep.

        The following aliases for this command have also been defined, and can be used
        as <alias> [string]:

          ls-aliases : List shell aliases
           ls-arrays : List array variables
         ls-bindings : List key-binding names for Readline
         ls-builtins : List available built-in commands
         ls-commands : List available commands (executables, functions, builtins, ...)
            ls-funcs : List shell function names
          ls-signals : List signal names
             ls-vars : List defined variables

        Examples

        ls-vars OPT
        : list all defined variables starting with OPT

        ls-signals | grep -i 'p\$'
        : list signals ending in p
        "
        docsh -TD
        return
    }

    compgen -A "$@"
}

alias ls-aliases='compgen-match alias'
alias ls-arrays='compgen-match arrayvar'
alias ls-bindings='compgen-match binding'
alias ls-builtins='compgen-match builtin'
alias ls-cmds='compgen-match command'
alias ls-exports='compgen-match export'
alias ls-funcs='compgen-match function'
alias ls-helptopics='compgen-match helptopic'
alias ls-jobs='compgen-match job'
alias ls-keywords='compgen-match keyword'
alias ls-setopts='compgen-match setopt'
alias ls-shopts='compgen-match shopt'
alias ls-signals='compgen-match signal'
alias ls-vars='compgen-match variable'
