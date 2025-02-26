# bash.d/ : Shell Function and Alias Definitions, and Environment Config

I used to symlink a single file, ~/.bash_functions, and source it from ~/.bashrc. Now
the alias, function, and environment variable definitions have been moved to
individual files in this directory, symlinked as ~/.bash.d/. Any files herein with a
'.sh' or '.bash' extension will be sourced from .bashrc.

Notes:

- Note to ponder, from the bash man page:

  For almost every purpose, aliases are superseded by shell functions.

- To see expanded aliases, use `type -a cmd-alias`, or hit Ctrl-Alt-e after typing the
  command, but before running it (repeatedly, for nested aliases).
