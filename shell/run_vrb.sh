run_vrb() {

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] && {

        : "Print command line to STDERR as it is being run

        Usage

          run_vrb [options] [--] <command-line ...>

        Options

          -v <n>
          : n is an integer indicating the verbosity level. If n > 1, the command line
            is printed. The default value is 2.

          -P
          : resolve the command name to either a shell builtin or file on the PATH, and
            modify the command line to be explicit about what is run (i.e. either
            'builtin command' or '/path/to/command').

        This function starts a subshell and issues \`set -x\`, which causes the command
        line to be printed on STDERR, prepended by \$PS4 (currently '$( sed -E 's/\\(\[|\])//g' <<< $PS4 )').

        If environment variable settings in the form of A=B are used at the start of the
        command line, the \`env\` command is added to ensure the command runs. Note that
        \`env\` is incompatible with running shell functions or builtins, so a command line
        like \`'A=B run_vrb command args'\` is recommended.

        Examples

          run_vrb git clone http://repo-url.com dir

          _v=1
          [[ \$foo == bar ]] && (( _v++ ))
          run_vrb -\$_v borg-go create

        Return status

        Usually the return status of the command, otherwise 2 if there is an option
        problem, or 124-6 if there is a problem determining the command name or type.
        "
        docsh -TD
        return
    }

    # Options
    # - NB, getopts respects '--' and advances OPTIND
    local _v=2 _P

    local flag OPTARG OPTIND=1
    while getopts ':v:P' flag
    do
        case $flag in
        ( v ) _v=$OPTARG ;;
        ( P ) _P=1 ;;
        ( \? ) err_msg 2 "unknown option: '$OPTARG'"; return ;;
        ( : ) err_msg 2 "missing argument for '$OPTARG'"; return ;;
        esac
    done
    shift $(( OPTIND - 1 ))


    ## split the command line into A=B env var parts, the command name, and args
    # - NB, I used to use array_match() in here, but that set up a function loop
    local i cmd _env evars=() args=()

    for (( i=1; i<=$#; i++ ))
    do
        if [[ $i == 1  &&  ${!i} == @(env|*/env) ]]
        then
            _env=1
            evars+=( "${!i}" )

        elif [[ ${!i} == *=* ]]
        then
            evars+=( "${!i}" )

        else
            cmd=${!i}
            break
        fi
    done

    [[ -v cmd ]] || return 124

    # command arguments
    local j=$(( i + 1 ))
    args+=( "${@:j}" )

    shift $#


    ## if A=B env var settings are present, the env command is needed
    [[ ${#evars[@]} -gt 0  &&  -z ${_env-} ]] &&
        evars=( "$(type -P env )" "${evars[@]}" )


    [[ -n ${_P-} ]] && {

        # resolve command to builtin or file
        # - type -t returns alias, keyword, function, builtin, file or ''
        local t vct types=()

        types=( $( type -at "$cmd" ) ) \
            || return 125

        for t in "${types[@]}"
        do
            [[ $t == @(alias|keyword|function) ]] && continue
            vct=$t
            break
        done

        # adjust command argument
        if [[ $vct == builtin ]]
        then
            cmd=( 'builtin' "$cmd" )

        elif [[ $vct == file ]]
        then
            # type -P gives path to executable
            cmd=$( type -P "$cmd" )

        else
            return 126
        fi
    }

    (
        [[ $_v -gt 1 ]] && set -x
        "${evars[@]}" "${cmd[@]}" "${args[@]}"
    )
}
