Functions used in .bashrc to setup the user environment, prompt, colours, etc.

- These files used to be in a file called ~/.bashrc_funcs, then they were sourced from
  ~/.bashrc.d/. They are sourced from ~/.bashrc.

- The files to be sourced may have extension '.sh' or '.bash'. They should always be
  sourced, not executed.

- The dependencies of the files should also be sourced, before the functions are
  called. These are listed in the file ...

- NB I tried to write a posix/dash compliant version of these, to be sourced from
  ~/.profile, but it was too hard: in particular, getting the output of find into the
  set builtin in order to augment the positional parameters and treat them like an
  array was insurmountable (in a robust way).

- The more complex functions should probably be converted to Python or Go.
