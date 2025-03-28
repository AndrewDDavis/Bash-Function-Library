# Bash Function Library ReadMe

The `.sh` and `.bash` files in the `lib/` directory tree contain shell function and
alias definitions. They are meant to be sourced during shell initialization or later
during an interactive session. The files do not have exutable permissions set, because
they are *not* meant to be executed.

Sourcing the files and running them as functions offers a few benefits:

  - Shell functions can fully integrate into an interactive session, including during
    shell initialization. This allows them to access, change, or set shell variables,
    as in the string and array functions. In contrast, a shell script runs in a child
    shell, which only allows access to exported variables, and they can't directly set
    variables in the parent shell.

  - For simple tasks, shell functions run more quickly than scripts or external
    programs, since no new process is required.

## The import_func Function

Many of the functions in the library are commonly used by other functions, e.g.
`str_to_words`, `array_match`, and so on. It's possible to add `source` commands to
import the needed functions, but the `import_func` function was written to facilitate
this. By default, it is expected that the `lib` directory of this library is symlinked
as `.bash_lib` in the home directory (refer to installation notes below). If so, adding
the following lines to `~/.bashrc` will make `import_func` available to import
dependency functions.

```sh
[[ -d ~/.bash_lib ]] &&
    source "$HOME"/.bash_lib/import_func.sh
```

The function definition files herein widely rely on access to `import_func`, so
the `source` line should be placed in the user's `~/.bashrc` file.

To easily import dependencies within scripts, you can export the function from an
interactive session with `export -f import_func`, or the file can be sourced at the
top of the script using the same line as above.

```sh
import_func docsh err_msg str_to_words array_match \
    || return 9
```

## Functions Used During Shell Initialization

Some of the functions are sourced early in `~/.bashrc` to set up the user environment,
prompt, colours, etc.:

  - `path_check_add`
    : Check the existence of a directory, and add it to the PATH variable if it isn't
      already present.

  - `path_check_symlink`
    : Check for symlinked directories that are both in the PATH, which causes duplicate
      results in command searches.

  - `path_has`
    : Check whether path is already part of the PATH variable.

  - `path_rm`
    : Print new PATH with an element removed.

  - `term_detect`
    : Sets the TERM_PROGRAM environment variable, after attempting to detect the
      current terminal emulator. Also sets the _term_nclrs variable, which some other
      functions look for to determine the number of colours supported by the terminal.

## Prompt Functions

...

## Supporting Functions

  - `docsh`
  - `err_msg`

## Other Useful Functions

  - `alias-resolve`
  - `realias`
  - `cd-wrapper`
  - `compgen-match`
  - `func-where`
  - `type-wrapper`
  - `vars-grep`

## Installation

  - `import_func` in `~/.bashrc`
  - use a symlink at `~/.bash_lib`, or set BASH_FUNCLIB

## Notes

- NB I tried to write a posix/dash compliant version of these, to be sourced from
  ~/.profile, but it was too hard: in particular, getting the output of find into the
  set builtin in order to augment the positional parameters and treat them like an
  array was insurmountable (in a robust way).

- The more complex functions should probably be converted to Python or Go, or at least
  to shell scripts rather than functions.

- Note to ponder, from the Bash man page:

  For almost every purpose, aliases are superseded by shell functions.

- To see expanded aliases, use `type -a cmd-alias`, or hit Ctrl-Alt-e after typing the
  command, but before running it (repeatedly, for nested aliases).
