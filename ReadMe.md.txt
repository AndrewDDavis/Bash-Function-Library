# Bash Function Library ReadMe

This dir contains shell function and alias definitions, as well as some environment
configuration.

The `bashrc` directory contains functions that are sourced first, and required early
in the parsing of `~/.bashrc`, in particular:

  - path_check_add
  - path_check_symlink
  - path_has
  - path_rm
  - err_msg
  - docsh
  - term_detect

It also contains functions that are commonly used by other functions, e.g. str_split,
array_match, and so on. To use these functions from within scripts, they should be
imported using the `import_func` function, like so:

```bash
source ~/.bash_funclib.d/import_func.sh

import_func docsh err_msg str_split array_match \
    || return
```

I used to symlink a single file, `~/.bash_functions`, and source it from `~/.bashrc`.
Now the alias, function, and environment variable definitions have been moved to
individual files in this directory, symlinked as `~/.bash_funclib.d/`. Any files herein
with a '.sh' or '.bash' extension will be sourced from `~/.bashrc`.

Notes:

- Note to ponder, from the Bash man page:

  For almost every purpose, aliases are superseded by shell functions.

- To see expanded aliases, use `type -a cmd-alias`, or hit Ctrl-Alt-e after typing the
  command, but before running it (repeatedly, for nested aliases).
