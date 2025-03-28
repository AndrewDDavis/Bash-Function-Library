import_func() {

    # function docs (relies on docsh imported below)
    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Import a function to use in a script or interactive shell

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

        Example 1

          # import dependencies in a script

          [[ \$( builtin type -t import_func ) == function ]] || {
              source ~/.bash_lib/import_func.sh \\
                  || return 63
          }

          import_func docsh err_msg \\
              || return 62

        Example 2

          # import all source files within a directory tree, e.g. for environment setup
          # in .bashrc

          BASH_FUNCLIB=~/.bashrc.d import_func -a
        "
        docsh -TD
        return
    }

    # clean-up routine
    trap '
        unset -f _xfn
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
    local libdir="$HOME"/.bash_lib

    [[ -n ${BASH_FUNCLIB-} ]] &&
        libdir=$BASH_FUNCLIB

    [[ -d $libdir ]] ||
        { err_msg 9 "libdir not found: '$libdir'"; return; }


    _xfn() {

        # add find args to exclude filename, possibly adding suffixes
        if [[ $1 == */ ]]
        then
            # directory
            find_cmd+=( -name "${1%/}" )

        elif [[ $1 == *@(.sh|.bash) ]]
        then
            # already has extension
            find_cmd+=( -name "$1" )

        else
            find_cmd+=( -name "${1}.sh" -o -name "${1}.bash" )
        fi
    }


    if [[ -v _all ]]
    then
        # import all files except those specified

        # - build a find command line to match filenames in the lib dir
        local find_cmd fn

        find_cmd=( "$( builtin type -P find )" -L "$libdir" ) \
            || return 9

        if [[ $# -gt 0 ]]
        then
            # - build file exclusion list using the construct:
            #   find ... \( -name .fdignore -o -name 'a file' \) -prune -o ... -print0
            find_cmd+=( '(' )

            _xfn "$1"

            for fn in "${@:2}"
            do
                find_cmd+=( -o )
                _xfn "$fn"
            done

            find_cmd+=( ')' -prune -o )
        fi

        # - NB, type f matches symlinked files, since we're using -L
        find_cmd+=( -type f \( -name '*.sh' -o -name '*.bash' \) -print0 )


        # Run find and import the selected files
        while IFS='' read -rd '' fn <&3
        do
            # shellcheck source=/dev/null
            source "$fn"

        done 3< <( "${find_cmd[@]}" )

        # NB, an alternative, with globstar set and filenames without newlines, would be
        # to use e.g.:
        #   for fn in .bash_lib/shell/**/*.sh; do source "$fn"; done

    else
        # import specified function(s)

        [[ $# -gt 0 ]] ||
            return 99

        # grep path and opts (recursive ERE, follow symlinks, limit to text-format files)
        local grep_cmd grep_ptn

        grep_cmd=( "$( builtin type -P grep )" -EIRl ) \
            || return 9

        # limit to .sh and .bash filenames
        grep_cmd+=( --include='*.sh' --include='*.bash' )

        local func_nm src_fns

        for func_nm in "$@"
        do
            if  [[ $( builtin type -at "$func_nm" ) == *function*
                && ! -v _force ]]
            then
                # skip existing function
                continue
            fi

            # match pattern for function definition in source file
            grep_ptn="^(${func_nm}[[:blank:]]*\(\)|function[[:blank:]]+${func_nm})"

            mapfile -t src_fns < <( "${grep_cmd[@]}" -e "$grep_ptn" "$libdir" )

            if [[ ${#src_fns[@]} -eq 1 ]]
            then
                # shellcheck source=/dev/null
                source "${src_fns[@]}"

            elif [[ ${#src_fns[@]} -eq 0 ]]
            then
                err_msg 1 "no source found for '$func_nm'"
                return

            else
                err_msg 1 \
                    "multiple source files found for '$func_nm'" \
                    "command line was '${grep_cmd[*]} -e $grep_ptn $libdir'"
                return
            fi
        done
    fi
}

# when sourcing this file, import supporting functions
import_func err_msg docsh \
    || return 62
