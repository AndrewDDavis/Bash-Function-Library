#!/usr/bin/env bash

mtdirx() {

    : "Test for an empty directory, with expressive return status codes

    Usage: mtdirx [-P] <path>

    This function uses the \`test\` shell builtin to evaluate the specified path, and
    return an expressive status code. In typical shell operation, a return status of 0
    represents success, and values > 0 represent failure.

    Return codes

      0  : empty directory
      1  : non-empty directory
      2  : not a directory
      3  : path not found

    If the path is a symlink, mtdirx follows it to evaluate the file it points to.
    To disable this behaviour and cause symlinks to return with status 3, add the
    '-P' option before the path.

    Since this function uses only the builtin \`test\` command rather than \`find\`,
    it does not rely on the user having read and execute permissions for the path.
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # -P option
    local _P
    [[ $# -gt 1  && $1 == -P ]] &&
        { _P=1; shift; }

    # path
    local _fn=$1
    shift

    [[ $# -eq 0 ]] ||
        return 2


    if [[ -n ${_P-}  && -L $_fn ]]
    then
        # symlink, and we're not dereferencing
        return 2

    elif [[ -d $_fn ]]
    then
        if [[ -s $_fn ]]
        then
            # non-empty directory
            return 1
        else
            # empty directory
            return 0
        fi

    elif [[ -e $_fn ]]
    then
        # not a directory
        return 2

    else
        # path not found
        return 3
    fi
}
