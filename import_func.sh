# shellcheck shell=bash

import_func() {

    # use docsh to print the docs
    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Import a function into a script or interactive shell

        Usage: import_func [-f] <function name> ...

        This function searches a directory tree for function definitions matching the
        requested name, and imports the function into the current shell session by sourcing
        the relevant file. By default, the search is performed in ~/.bash_funclib.d (which
        can be a symlink), but this can be overridden by setting the BASH_FUNCLIB variable.
        Symlinks within the library are followed.

        Normally, this function will not (re)import functions that have the same name as a
        function that's already defined. Force the sourcing of the relevant files by using
        the -f option.
        "
        docsh -TD
        return
    }

    # -f option
    local _force
    [[ ${1-} == -f ]] &&
        { _force=1; shift; }

    [[ $# -gt 0 ]] ||
        return 99

    # check libdir
    local libdir

    if [[ -v BASH_FUNCLIB ]]
    then
        libdir=$BASH_FUNCLIB
    else
        libdir=~/.bash_funclib.d
    fi

    [[ -d $libdir ]] ||
        { err_msg 2 "libdir not found: '$libdir'"; return; }

    local fn
    for fn in "$@"
    do
        if [[
            ! -v _force
            && $( type -at "$fn" ) == *function*
        ]]
        then
            # skip existing function
            continue
        fi

        # search for the source file with grep
        local grep_cmd ptn grep_cmdline src_fns

        grep_cmd=$( type -P grep ) \
            || return

        ptn="^(${fn}[[:blank:]]*\(\)|function[[:blank:]]+${fn})"

        grep_cmdline=( "$grep_cmd" -ERl -e "$ptn" "$libdir" )

        mapfile -t src_fns < <( "${grep_cmdline[@]}" )

        if [[ ${#src_fns[@]} -eq 1 ]]
        then
            # shellcheck source=/dev/null
            source "${src_fns[@]}"

        elif [[ ${#src_fns[@]} -eq 0 ]]
        then
            err_msg 1 "no source found for '$fn'"

        else
            err_msg 1 \
                "multiple source files found for '$fn'" \
                "command line was '${grep_cmdline[*]}'"
        fi
    done
}

# now import supporting functions
import_func err_msg docsh
