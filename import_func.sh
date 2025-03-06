import_func() {

    # function docs (relies on docsh imported below)
    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Import a function to use in a script or interactive shell

        Usage

            import_func [-f] <function name> ...
            import_func -a [file name] ...

        In its default mode of operation (without -a), this function searches a
        directory tree for function definitions matching the requested name, and imports
        the function into the current shell by sourcing its file.

        By default, the search is performed in ~/.bash_library.d, but the library path
        may be overridden by setting the BASH_FUNCLIB variable. Symlinks within the
        library are dereferenced and followed.

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

        Example: import dependencies in a script

          # import dependencies
          [[ \$( builtin type -t import_func ) == function ]] || {
              source ~/.bash_library.d/import_func.sh \\
                  || return 63
          }

          import_func docsh err_msg \\
              || return 62
        "
        docsh -TD
        return
    }

    # clean-up routine
    trap '
        unset -f _fn_list
        trap - return
    ' RETURN

    # options
    local _force _all
    local _flag OPTARG OPTIND=1
    while getopts ':af' _flag
    do
        case $_flag in
            ( a ) _all=1 ;;
            ( f ) _force=1 ;;
            ( \? ) err_msg 2 "Unrecognized option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "Missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # check for expected library path
    local libdir

    if [[ -v BASH_FUNCLIB ]]
    then
        libdir=$BASH_FUNCLIB
    else
        libdir=~/.bash_library.d
    fi

    [[ -d $libdir ]] ||
        { err_msg 9 "libdir not found: '$libdir'"; return; }


    if [[ -v _all ]]
    then
        # import all files except those specified
        local fn fnxs=() find_cmd find_cmdline

        find_cmd=$( builtin type -P find ) \
            || return

        find_cmdline=( "$find_cmd" -L "$libdir" )

        if [[ $# -gt 0 ]]
        then
            # build file exclusion list using the construct:
            # find ... \( -name .fdignore -o -name 'a file' \) -prune -o ... -print0
            find_cmdline+=( '(' )

            _fn_list() {

                # add 1 or 2 filenames depending on filename suffix

                if [[ $1 == */ ]]
                then
                    fnxs=( -name "${1%/}" )

                elif [[ $1 == *@(.sh|.bash) ]]
                then
                    fnxs=( -name "$1" )

                else
                    fnxs=( -name "${1}.sh" -o -name "${1}.bash" )
                fi
            }

            _fn_list "$1"
            find_cmdline+=( "${fnxs[@]}" )

            for fn in "${@:2}"
            do
                _fn_list "$fn"
                find_cmdline+=( -o "${fnxs[@]}" )
            done

            find_cmdline+=( ')' -prune -o )
        fi

        # - NB, type f matches symlinked files, since we're using -L
        find_cmdline+=( -type f \( -name '*.sh' -o -name '*.bash' \) -print0 )

        # run find and import the selected files
        while IFS='' read -rd '' fn <&3
        do
            # shellcheck source=/dev/null
            source "$fn"

        done 3< <( "${find_cmdline[@]}" )

        # NB, an alternative, with globstar set and filenames without newlines, would be
        # to use:
        #   for fn in .bash_library.d/bashrc/**/*.sh; do source "$fn"; done

    else
        # import specified function(s)

        [[ $# -gt 0 ]] ||
            return 99

        local fn src_fns grep_cmd grep_ptn grep_cmdline

        grep_cmd=$( builtin type -P grep ) \
            || return

        for fn in "$@"
        do
            if [[
                $( builtin type -at "$fn" ) == *function*
                && ! -v _force
            ]]
            then
                # skip existing function
                continue
            fi

            # search for the source file with grep
            grep_ptn="^(${fn}[[:blank:]]*\(\)|function[[:blank:]]+${fn})"

            grep_cmdline=( "$grep_cmd" -EIRl -e "$grep_ptn" "$libdir" )

            mapfile -t src_fns < <( "${grep_cmdline[@]}" )

            if [[ ${#src_fns[@]} -eq 1 ]]
            then
                # shellcheck source=/dev/null
                source "${src_fns[@]}"

            elif [[ ${#src_fns[@]} -eq 0 ]]
            then
                err_msg 1 "no source found for '$fn'"
                return

            else
                err_msg 1 \
                    "multiple source files found for '$fn'" \
                    "command line was '${grep_cmdline[*]}'"
                return
            fi
        done
    fi
}

# when sourcing this file, import supporting functions
import_func err_msg docsh \
    || return 62
