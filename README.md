# Bash Function Library ReadMe

TODO:
- need to go through the other func files and check for dependencies, and files
  that only set env vars, not aliases and funcs.
- three types of files:
  + functions (e.g. docsh, basename, array_match)
  + scripts (i.e. convert these from functions to scripts)
  + aliases and env vars only (these can go into Shell Operation/Bash_Env, and be imported separatetly with a simple loop)
- candidates for revision:
  + file_ops/zip.sh
  + file_ops/cd_mkdir_pushd.sh
  + file_search/ls.sh
  + net_and_disks/syncthing.sh
  + net_and_disks/openssl.sh
  + net_and_disks/w3m.sh
  + programming/python.sh
  + programming/go.sh
  + programming/haskell.sh
  + research_tools.sh
  + shell/history_fc.sh
  + sys_admin/vmware.sh


The files in this directory tree with '.sh' or '.bash' extensions contain shell
functions and alias definitions, as well as some environment configuration. They are
meant to be sourced during shell initialization, or from partner files as dependencies.
Most are *not* meant to be executed.

Some of the functions are sourced early in `~/.bashrc` to set up the user environment,
prompt, colours, etc.:

  - path_check_add
  - path_check_symlink
  - path_has
  - path_rm
  - err_msg
  - docsh
  - term_detect

It also contains functions that are commonly used by other functions, e.g. str_to_words,
array_match, and so on. To use these functions from within scripts, they should be
imported using the `import_func` function, like so:

```bash
source ~/.bash_lib/import_func.sh

import_func docsh err_msg str_to_words array_match \
    || return
```

Within the script files of this library, access to `import_func` will be assumed, so
the `source` line should be placed in the user's `~/.bashrc` file.

I used to symlink a single file, `~/.bash_functions`, and source it from `~/.bashrc`.
Now the alias, function, and environment variable definitions have been moved to
individual files in this directory, symlinked as `~/.bash_lib/`. Any files herein
with a '.sh' or '.bash' extension will be sourced from `~/.bashrc`.


## Notes

- NB I tried to write a posix/dash compliant version of these, to be sourced from
  ~/.profile, but it was too hard: in particular, getting the output of find into the
  set builtin in order to augment the positional parameters and treat them like an
  array was insurmountable (in a robust way).

- The more complex functions should probably be converted to Python or Go.

- Note to ponder, from the Bash man page:

  For almost every purpose, aliases are superseded by shell functions.

- To see expanded aliases, use `type -a cmd-alias`, or hit Ctrl-Alt-e after typing the
  command, but before running it (repeatedly, for nested aliases).
