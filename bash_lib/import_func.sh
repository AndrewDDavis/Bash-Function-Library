# Ensure Bash > v4.0 (from Feb 2009), so mapfile is available
(( ${BASH_VERSINFO[0]-0} > 4 )) \
    || printf >&2 '%s\n' "Error (import_func.sh): Bash v4.0 or higher required"

import_func() {

    # function docs (relies on docsh imported below)
    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : """Import a function to use in a script or interactive shell

        Usage

            import_func [-f] <function name> ...
            import_func -a [file name] ...

        In its default mode of operation (without -a), this function searches a
        directory tree for function definitions matching the specified name(s). The
        functions are then imported into the current shell session by applying the
        source built-in command to the relevant files.

        By default, the ~/.bash_lib/ directory is searched, but the library path may
        be overridden by setting the BASH_FUNCLIB variable. Symlinks within the library
        are dereferenced and followed. Source files are expected to have a .sh or .bash
        file extension.

        Options

          -a
          : Import all files: import_func will import every file in the library tree
            that has a .sh or .bash extension, except those listed on the command line.

            The file extension may be omitted when listing files. Subdirectories of the
            library may also be excluded by using a '/' at the end of the file name.

          -f
          : Force reimport: normally, import_func will not (re)import a function if a
            function with the same name is already defined. This option forces such
            functions to be reimported by sourcing the relevant file.

          -l
          : Import from local directory. Instead of using ~/.bash_lib or BASH_FUNCLIB,
            this searches within the directory tree of the source file of the calling
            function or script, after resolving any symlinks.

            Very useful for larger projects that have their own repository e.g. under
            modules/, with supporting functions spread over multiple files. It also
            keeps the supporting functions out of the main interactive namespace. This
            works as expected across various namespace scopes, e.g. for functions
            previously imported into the interactive namespace, for sourced scripts, and
            for the separate namespaces of executed scripts and subshells.

            Note that import_func will not import the source file of the calling
            function or script, to prevent an endless loop from occurring.

          -v
          : Print verbose messages during the function operation.

        The function normally returns 0 (true), but returns 62 if it cannot find the
        funclib directory, 63 if it cannot find a source file for a function named
        on the command line, or 64 if it finds multiple source files. It also returns
        3, 4 or 5 if there is a problem parsing the command-line arguments, or 9 if
        executables for the find or grep command cannot be located.

        Example 1

          # import dependencies in a script

          [[ \$( builtin type -t import_func ) == function ]] || {
              source ~/.bash_lib/import_func.sh \\
                  || return 9
          }

          import_func docsh err_msg \\
              || return

        Example 2

          # import all source files within a directory tree, e.g. for environment setup
          # in .bashrc

          BASH_FUNCLIB=~/.bashrc.d import_func -a
        """
        docsh -TD
        return
    }

    # running with functrace causes the cleanup trap to run on every function return
    # TODO: make the cleanup function more discerning
    [[ $( shopt -o functrace ) == *off ]] \
        || { err_msg 48 "import_func should not be run with functrace enabled"; return; }

    # Set a variable so child import_func calls don't run the cleanup routine
    # - NB, care is taken around later 'source' calls, which shouldn't see the trap.
    #   The return trap is reset before calling source, and restored after the call.
    # - Recall that child function calls don't inherit a return trap, except for
    #   "trap -- '' RETURN". As long as IMPORT_FUNC_LVL is set, child import_func calls
    #   won't call the cleanup routine in their trap.
    if [[ -v IMPORT_FUNC_LVL ]]
    then
        # parent import_func already running
        # - manage the LVL variable to improve reporting through _verb_msg
        (( IMPORT_FUNC_LVL++ ))
        trap '
            (( IMPORT_FUNC_LVL-- ))
            trap - return
        ' RETURN

        # retain verbosity of parent call
        [[ -v _impf_verb ]] \
            && local -I _impf_verb \
            || err_msg w "IMPORT_FUNC_LVL=$IMPORT_FUNC_LVL, but _impf_verb not set"

        # functions should also be set, or something fishy is going on
        builtin declare -F _def_libdir >/dev/null \
            || err_msg w "IMPORT_FUNC_LVL=$IMPORT_FUNC_LVL, but _def_libdir not set"

    else
        # no parent import_func running
        local IMPORT_FUNC_LVL=1
        local _impf_verb=1

        # Namespace cleanup routine
        # - unset local functions and reset the return trap.
        # - commonly, the files sourced below also contain calls to import_func. The
        #   logic of the IMPORT_FUNC_LVL variable above is meant to ensure that this
        #   cleanup function isn't called when child import_func calls return.
        # - NB, use 'declare -tf _impf_cleanup' if you want to be able to reset the return
        #   trap from inside the cleanup function; otherwise, use 'trap - return' in the
        #   'body' of the trap call.
        local _subfuncs=()
        trap '
            _verb_return $?
            unset -f "${_subfuncs[@]}"
            trap - return
        ' RETURN

        _subfuncs+=( _verb_return )
        _verb_return() {

            _verb_msg 2 "_verb_return triggered with LVL=$IMPORT_FUNC_LVL"

            (( _impf_verb > 2 )) && {
                _verb_msg 3 "  code $1, ln ${BASH_LINENO[0]} of $( basename "${BASH_SOURCE[1]}" ):"
                _verb_msg 3 "    $( sed -nE "${BASH_LINENO[0]} { s/^[[:blank:]]+//; p; }" < "${BASH_SOURCE[1]}" )"
                local m decs
                mapfile -t decs < <( declare -p FUNCNAME BASH_COMMAND )
                for m in "${decs[@]}"; do _verb_msg 3 "  ${m#declare ?? }"; done
            }
        }

        # subfunctions to be unset on return
        # - NB, although care has been taken to save loading time of these functions in
        #   child calls, reading function definitions takes very little time in Bash. It
        #   actually takes <10 us for a resonably short function, or ~ 1 us longer than
        #   a no-op. It somehow seems to take less time than a no-op with a string
        #   argument of the same function definition.
        _subfuncs+=( _verb_msg )
        _verb_msg() {

            # Print a message if _verb setting is high enough
            # Usage: _verb_msg <level> "message body"
            # - e.g. pass level=0 or 1 to usually print, 2 to print with -v, 3 with -vv, etc.
            # NB:
            # - _impf_verb=1 by default
            # - could also use 'err_msg i ...' here
            # ensure return status is 0
            (( _impf_verb < $1 )) \
                && return

            local i=2 func=${FUNCNAME[1]-}
            while [[ $func == _* ]]
            do
                # underscore functions are probably not the context we want
                if [[ -n ${FUNCNAME[i]-} ]]
                then
                    func=${FUNCNAME[i]}
                else
                    break
                fi
                (( i++ ))
            done

            # report LVL for import_func calls
            [[ $func == import_func ]] \
                && func+=" (LVL=${IMPORT_FUNC_LVL})"

            printf >&2 '%s\n' "${func}: $2"
        }

        _subfuncs+=( _def_libdir )
        _def_libdir() {

            # define search root for source files
            local caller_srcfn
            if [[ -v _local ]]
            then
                # use source-file dir as library path

                # TODO:
                # - will this fail if FUNCNAME[1] == source? Could this happen?

                caller_srcfn=$( physpath "${BASH_SOURCE[1]}" ) \
                    || { err_msg 9 "physpath error on BASH_SOURCE[1]: '${BASH_SOURCE[1]}'"; return; }

                libdir=$( dirname -- "$caller_srcfn" )

                # exclude the caller's source file, to prevent an endless loop
                x_paths+=( "$caller_srcfn" )

            else
                # check env var
                [[ -z ${BASH_FUNCLIB-} ]] \
                    || libdir=$BASH_FUNCLIB
            fi

            [[ -d $libdir ]] \
                || { err_msg 62 "libdir not found: '$libdir'"; return; }

            _verb_msg 2 "libdir: '$libdir'"
        }

        _subfuncs+=( _def_find_cmd )
        _def_find_cmd() {

            # - use find to match filenames in libdir
            find_cmd=( "$( builtin type -P find )" -L "$libdir" ) \
                || { err_msg 9 "no executable found for find"; return; }

            # - build file exclusion list using the construct:
            #   find ... \( -name .fdignore -o -name 'a file' \) -prune -o ... -print0
            if (( ${#fns[@]} > 0 ))
            then
                find_cmd+=( '(' )

                local i=0 fn np_arg
                for fn in "${fns[@]}"
                do
                    # add find args to exclude filename, possibly adding suffixes

                    (( i > 0 )) && find_cmd+=( '-o' )

                    # filename or path
                    np_arg='-name'
                    [[ ${fn%/} == */* ]] \
                        && np_arg='-path'

                    if [[ $fn == */ ]]
                    then
                        # directory
                        find_cmd+=( "$np_arg" "${fn%/}" )

                    elif [[ $fn == *@(.sh|.bash) ]]
                    then
                        # already has extension
                        find_cmd+=( "$np_arg" "$fn" )

                    else
                        find_cmd+=( "$np_arg" "${fn}.sh" -o "$np_arg" "${fn}.bash" )
                    fi

                    (( ++i ))
                done

                find_cmd+=( ')' -prune -o )
            fi

            # - NB, type f matches symlinked files, since we're using -L
            find_cmd+=( -type f \( -name '*.sh' -o -name '*.bash' \) -print0 )

            _verb_msg 3 "find_cmd: '${find_cmd[*]}'"
        }

        _subfuncs+=( _def_grep_cmd )
        _def_grep_cmd() {

            # grep path and opts
            # - recursive ERE, limit to text-format files, follow symlinks
            # - used to have -l, but need context to make assoc. array
            grep_cmd=( "$( builtin type -P grep )" -EIR ) \
                || { err_msg 9 "no executable found for grep"; return; }

            # limit to filenames with suffixes: .sh or .bash
            grep_cmd+=( --include='*.sh' --include='*.bash' )
        }

        _subfuncs+=( _def_grep_cmdln )
        _def_grep_cmdln() {

            # TODO:
            # - add exclude args for x_paths

            # build pattern and define whole grep command-line
            local func_alts grep_ptn

            # array to string: (func1|func2|func3)
            func_alts=\($( IFS='|'; printf '%s\n' "${fns[*]}"; )\)

            # match pattern for function definitions in source files
            grep_ptn="^(${func_alts}[[:blank:]]*\(\)|function[[:blank:]]+${func_alts})"

            # old ptn, within func_nm loop:
            # grep_ptn="^(${func_nm}[[:blank:]]*\(\)|function[[:blank:]]+${func_nm})"

            grep_cmdln=( "${grep_cmd[@]}" -e "$grep_ptn" "$libdir" )
            _verb_msg 3 "grep command-line: ${grep_cmdln[*]@Q}"
        }

        _subfuncs+=( _match_src_fns )
        _match_src_fns() {

            # match source filenames using grep_cmd, and parse the result
            local grep_out
            mapfile -t grep_out < <( "${grep_cmdln[@]}" )

            # now grep_out is an indexed array of lines comprising filenames and matched lines
            # - like: /home/andrew/.bash_lib/shell_scripting/err_msg.sh:err_msg() {
            (( ${#grep_out[@]} == "${#fns[@]}" )) \
                || { err_msg 63 "number of grep_out should match fns:" "$( declare -p grep_out fns )"; return; }

            # make an assoc. array of functions to source files
            local ln rgx fn func
            for ln in "${grep_out[@]}"
            do
                # ensure 1 and only 1 colon in each result
                [[ $ln == *:*  && $ln != *:*:* ]] \
                    || { err_msg 9 "unexpected grep_out: '$ln'"; return; }

                # - NB, per Bash manpage, a function name can be any unquoted shell word
                #   that does not contain $.
                rgx='^(.*):(([^[:blank:]$]+)[[:blank:]]*\(\)|function[[:blank:]]+([^[:blank:]$]+))'
                [[ $ln =~ $rgx ]] \
                    || { err_msg 9 "regex did not match ln: '$ln'"; return; }

                fn=${BASH_REMATCH[1]}
                func=${BASH_REMATCH[3]}
                [[ -n $func ]] \
                    || func=${BASH_REMATCH[4]}

                src_fns[$func]=$fn
            done

            _verb_msg 2 "matched source files: '$( declare -p src_fns )'"
        }

        _subfuncs+=( _imp_fn )
        _imp_fn() {

            # store and mask the return trap, if set, so it doesn't fire on returning
            # from source call
            # - NB, now that I've put this logic inside a function, that should really
            #   solve the original issue; since I'm not setting the trace attribute of
            #   this function, it should not see the return trap, unless the user set -T.
            local _rt=$( trap -p return )

            [[ -z ${_rt-} ]] \
                || trap - return

            _verb_msg 2 "sourcing '$1'"

            # shellcheck source=/dev/null
            source "$1"

            # restore trap
            [[ ${_rt-} == trap\ * ]] \
                && eval "$_rt"
        }
    fi

    # options
    local  _all _force _local
    local _flag OPTARG OPTIND=1
    while getopts ':aflv' _flag
    do
        case $_flag in
            ( a ) _all=1 ;;
            ( f ) _force=1 ;;
            ( l ) _local=1 ;;
            ( v ) (( _impf_verb++ )) ;;
            ( : )  err_msg 2 "missing argument for option $OPTARG"; return ;;
            ( \? ) err_msg 3 "unrecognized option: '-$OPTARG'"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))


    # positional args are function or file names
    local i fn fns=( "$@" )
    shift $#
    _verb_msg 3 "initial fns: '${fns[*]}'"


    if [[ ! -v _all  && ! -v _force ]]
    then
        # filter out known function names to prevent re-importing
        # - do this up front to return as quickly as possible if there's nothing to do
        # - NB, running this loop for a few fns takes only ~ 30 us (*micro-seconds*), but
        #   can save time down the line.
        for i in "${!fns[@]}"
        do
            builtin declare -F "${fns[i]}" >/dev/null \
                && { _verb_msg 2 "ignoring known: '${fns[i]}'"; unset 'fns[i]'; }
        done

    elif [[ -v _all ]]
    then
        # exclude source files of all calling functions, to prevent circularity
        for fn in "${BASH_SOURCE[@]:1}"
        do
            fn=$( physpath "$fn" ) \
                || return

            array_match fns "$fn" \
                || fns+=( "$fn" )
        done
    fi

    [[ ${#fns[@]} -eq 0  && ! -v _all ]] \
        && return


    # curtail endless loop of function calls
    # - this can occur if a function is called from one of its dependencies
    # - analagous situation:
    #   foo() { (( i++ )); bar; }
    #   bar() { (( i > 100 )) && { array_match -c FUNCNAME foo; return; }; foo; }
    #   i=0; foo
    # - this simple strategy was adopted rather than, e.g. trying to count the number
    #   of occurrences of import_func in the FUNCNAME stack
    (( ${#FUNCNAME[@]} < 200 )) || {
        printf >&2 '%s\n' "Error (import_func): possible function call loop" \
            "    $( declare -p FUNCNAME )"
        return 81
    }

    # define libdir and excluded paths for local call
    local x_paths=() libdir="$HOME"/.bash_lib
    _def_libdir || return

    if [[ -v _all ]]
    then
        # import all files from libdir (with exceptions)
        local find_cmd
        _def_find_cmd || return

        # Run find and import the selected files
        while IFS='' read -rd '' fn <&3
        do
            _imp_fn "$fn"

        done 3< <( "${find_cmd[@]}" )  # print0 at end?

    else
        # find and import specified function(s)

        # Strategy: the pattern is produced from all the function names, so grep only
        #   has to run once. If we get 1 source file for each function name, we will
        #   import them all, assuming there's 1 for each. Then at the end, check to
        #   make sure all requested functions are defined.

        # match source filenames using grep
        [[ -v grep_cmd ]] \
            || {
            local grep_cmd
            _def_grep_cmd || return
        }

        local grep_cmdln
        _def_grep_cmdln || return

        local -A src_fns=()
        _match_src_fns || return

        local func
        for func in "${!src_fns[@]}"
        do
            # skip if func was imported already, e.g. as a dependency
            [[ ! -v _force ]] \
                && builtin declare -F "$func" >/dev/null \
                && continue

            # skip exclusions from -l
            [[ -v x_paths[*] ]] \
                && array_match x_paths "${src_fns[$func]}" \
                && continue

            # import
            _imp_fn "${src_fns[$func]}"
        done
    fi
    return 0
}

# Import supporting functions when sourcing this file
# - We don't use a _deps array for this, since there can be a namespace collision when
#   the this file is sourced, and _deps is defined in the caller
# - NB, since these functions are used within import_func(), they should not call
#   import_func -l when they are executed. This could set up an endless loop!
#   OTOH, calling import_func in the base of their source files is fine.
#   Of course, these functions are some of the most important ones to the system, so
#   their stability is paramount, and this call will only fail on very serious problems,
#   such as missing libdir or grep command.
import_func -f err_msg docsh physpath array_match \
    || return

# dirname too, but we can fall back on the binary
import_func basename dirname

# printf >&2 '%s\n' "DEBUG: returning from import_func.sh"
