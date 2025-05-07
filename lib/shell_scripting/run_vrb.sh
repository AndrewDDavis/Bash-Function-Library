# deps
import_func is_int \
    || return

run_vrb() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Print command line to STDERR as it is being run

        Usage: run_vrb [options] [--] <command-line ...>

        This function runs the command line with the xtrace (set -x) option enabled.
        This causes the command line to be printed on STDERR as it is executed,
        prepended by the \$PS4 string (currently '$( sed -E 's/\\(\[|\])//g' <<< $PS4 )').

        Options

          -v <n>
          : n is an integer indicating the verbosity level. If n > 1, the command line
            is printed. The default value is 2.

          -P
          : resolve the command name to either a shell builtin or file on the PATH, and
            modify the command line to be explicit about what is run (i.e. either
            'builtin command' or '/path/to/command').

        If environment variable settings in the form of A=B are used at the start of the
        command line, the env command is prepended to ensure the command runs. Note that
        env is incompatible with running shell functions or builtins, so a command line
        like 'A=B run_vrb command args' is recommended.

        The return status code is usually the return status of the command line, but may
        be 2 if there was an option problem, or 124-6 if there was a problem determining
        the command name or type.

        Examples

          run_vrb git clone http://repo-url.com dir

          _v=1
          [[ \$foo == bar ]] && (( _v++ ))
          run_vrb -\$_v borg-go create
        "
        docsh -TD
        return
    }

    ## Defaults and options
    # - NB, getopts breaks the loop on '--' and advances OPTIND
    local _v=2 setx _P

    local flag OPTARG OPTIND=1
    while getopts ':v:P' flag
    do
        case $flag in
        ( v )
            is_int "$OPTARG" \
                || return
            _v=$OPTARG
        ;;
        ( P ) _P=1 ;;
        ( \? ) err_msg 2 "unknown option: '$OPTARG'"; return ;;
        ( : ) err_msg 2 "missing argument for '$OPTARG'"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))


    # check for set -x in the current shell
    (( _v > 1 )) && [[ $- != *x* ]] \
        && setx=1


    ## Further arguments form the command line to be executed
    # - split it into A=B args, the command name, and command args
    # - NB, I used to use array_match() in here, but that caused a function loop (!)
    local i _env eargs=() \
        cmd=() args=()

    for (( i=1; i<=$#; i++ ))
    do
        if [[ $i -eq 1  &&  ${!i} == @(env|*/env) ]]
        then
            # env command
            _env=1
            eargs+=( "${!i}" )

        elif [[ ${!i} == *=* ]]
        then
            # env-var setting
            eargs+=( "${!i}" )

        else
            # command, followed by args
            cmd[0]=${!i}
            (( i++ ))
            args+=( "${@:i}" )
            shift $#
            break
        fi
    done

    [[ -v cmd[*] ]] \
        || return 124


    # if A=B env var settings are present, the env command is needed
    [[ ${#eargs[*]} -gt 0  && ! -v _env ]] \
        && eargs=( "$( builtin type -P env )" "${eargs[@]}" )


    if [[ -v _P ]]
    then
        # resolve command to builtin or file
        # - NB, 'type -at' returns multi-line string containing alias, keyword,
        #   function, builtin, file or ''
        local types
        types=$( builtin type -at "${cmd[0]}" ) \
            || return 125

        # adjust command argument
        if [[ $types == *builtin* ]]
        then
            cmd=( builtin "${cmd[0]}" )

        elif [[ $types == *file* ]]
        then
            cmd[0]=$( builtin type -P "${cmd[0]}" )

        else
            return 126
        fi
    fi


    # run command line
    [[ -v setx ]] \
        && set -x

    "${eargs[@]}" "${cmd[@]}" "${args[@]}"

    { [[ -v setx ]] \
        && set +x; } 2>/dev/null
}
