# TODO:
# is there a place for a compound command like this?
#   while troubleshooting bind-mounts, used commands like:
#
#   ```sh
#   systemctl --user --all |
#       egrep --color=always 'mount|device|gvfs' |
#       egrep -v '/(proc|run|sys|dev)/' |
#       sed 's/                                    loaded/ loaded/' |
#       less -ES --redraw-on-quit
#   ```

scw() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Convenience wrapper for systemctl command lines

        This function saves typing compared to the full systemctl command, including
        shorter aliases to command names, shorter option names for the Systemd context,
        and automatic invocation of 'sudo' when necessary (i.e. when using the system
        context as non-root user).

        Usage: scw [context] [command] [arguments ...]

        Possible values for Systemd context argument:

          -u | --user
          -s | --system (default)
          -r | --runtime
          -g | --global

        The command may be one of systemctl's usual command names or the scw aliases
        shown below. Any further arguments are passed to systemctl after the command,
        as usual. Running with no command invokes \`systemctl list-units\` and passes
        the output to a pager (see SYSTEMD_LESS), as usual.

        For many commands, the arguments can include unit names, PIDs, paths, or
        patterns, which are assessed as shell glob expressions. Refer to \`man glob(7)\`
        for details, noting that extended expressions of the form '@(foo|bar)' are not
        supported, but multiple glob patterns may be issued and the results will combine
        as with a logical OR.

        Notable systemctl commands and scw aliases:

          ( list-unit-files | lsf | find ) [pattern]
          : List unit-files. If a pattern is provided, only unit files that match will
            be listed. If the pattern is a simple keyword, scw will expand it into a
            wildcard expression of the form '*...*'.

          ( list-units | ls | lsu | ls-all | lsu-all ) [pattern]
          : List units matching a glob pattern. This is the default when systemctl is
            run without a command. The 'all' variants show units that are loaded but
            inactive, in addition to the active ones. If the pattern is a simple
            keyword, scw will expand it into a wildcard expression of the form '*...*'.

          ( list-timers | lst ) [pattern]
          : List timer units matching the pattern, and show useful details such as when
            they were last run and when they will fire next.

          list-(automounts|paths|sockets|timers|dependencies) | --state=...
          : List various unit types or states from those that are currently loaded in
            memory.

          status [--full] [pattern]
          : With no arguments, shows a tree-view of running services and subprocesses.
            With a pattern, shows unit state, unit file(s), and recent log. Use
            journalctl or jcw for more log output. --full prevents shortening of long
            lines in the output.

          show [pattern]
          : Show properties of units, jobs, or the manager itself. This is more
            machine-readable output of the configuration, whereas humans generally want
            'status' or 'cat'. Use --all to include properties that are not set.

          cat UNIT
          : Print unit file and any overrides.

          edit UNIT
          : Edit the override for a unit file, creating it if necessary.

          help UNIT
          : Show man page.

          start, stop, restart UNIT
          : Control the unit's present state.

          enable, disable, mask UNIT
          : Set unit state for next restart. Use --now to also start or stop the unit.

          reload | kill UNIT
          : Tell a unit to reload its config, or send it a signal.

          daemon-reload
          : Reload the Systemd configuration: reruns all generators, reloads all unit
            files, and recreates the dependency tree.

          get-default
          : Show the default target to boot into. Also has a set- version.

          show-environment
          : Show the environment block that is passed to all processes spawned by
            Systemd. Also has set-, import-, and unset- variants.

          log-level [LEVEL] | service-log-level SERVICE [LEVEL]
          : Show or set the current maximum log level of a service or the manager. The
            possible level values are 'emerg', 'alert', 'crit', 'err', 'warning',
            'notice', 'info', and 'debug'.

          log-target [TARGET] | service-log-target SERVICE [TARGET]
          : Show or set the current log destination of the manager. The possible target
            values are 'console' (log to the attached tty), 'console-prefixed' (similar,
            but with expanded prefixes), 'kmsg' (log to the kernel circular log buffer),
            'journal' (log to the journal), 'journal-or-kmsg', 'auto' (the default), and
            'null' (disable log output).

          default | rescue | emergency
          : Enter the specified mode, as in e.g. 'systemctl isolate default.target'.

          halt | poweroff | reboot | soft-reboot [--force] [--when ...]
          : Shut down the system. Halt leaves the hardware powered on. The '--when'
            option can be used schedule a shut down, or cancel it with '--when=cancel'.
            Reboot also has several options related to '--firmware-setup' and
            '--boot-loader-...'. Soft-reboot only reboots user space.

          sleep | suspend | hibernate | hybrid-sleep | suspend-then-hibernate
          : Put system in specified state, where sleep actually chooses a target
            automatically.

        Examples

          # List units (services, mounts, sockets, timers, targets, ...). By default,
          # only units that are active, have pending jobs, or have failed are shown.
          # To include inactive and failed units, use the -all variant.
          scw [-u] [ ls | ls-all ] [--no-pager] [pattern]

          # status and recent log of a unit (from the most recent invocation)
          # - show more output with --full
          # - use journalctl --[user-]unit=... for output from earlier invocations
          scw [-u] status [--full] [pattern | PID]

          # tree-view of dependencies (wanted, required, ...)
          # - shows default.target, unless you specify another, e.g. local-fs.target or
          #   rsync.service.
          # - can show the tree for everything with --all (but that's too busy)
          # - see what must start before a unit with --after
          # - show what depends on a unit with --reverse
          scw [-u] list-dependencies [unit]

          # show all nuances of dependencies for a unit (wanted, requiers, after, ...)
          scw [-u] show <unit>
        "
        docsh -DT
        return
    }

    # Ensure smooth return on errors
    trap '
        trap-err $?
        return
    ' ERR

    trap '
        trap - ERR RETURN
        unset -f _sc_call _is_keyword _expand_keyword
    ' RETURN


    ### Configure systemctl command call

    # check for systemctl
    [[ -n $( command -v systemctl ) ]] ||
        err_msg 2 "systemctl not found"

    # parse flag for systemd context
    local ctx="--system"

    case $1 in
        ( -u | --user    ) ctx="--user";    shift ;;
        ( -s | --system  ) ctx="--system";  shift ;;
        ( -r | --runtime ) ctx="--runtime"; shift ;;
        ( -g | --global  ) ctx="--global";  shift ;;
    esac

    # systemctl command call
    _sc_call() {

        local cmd_words=( systemctl )

        [[ -z ${_use_sudo-} ]] ||
            cmd_words=( sudo "${cmd_words[@]}" )

        (
            set -x
            "${cmd_words[@]}" "$ctx" "$@"
        )
    }

    _expand_keyword() {

        # if last argument is a keyword, expand it into a wildcard pattern

        # do nothing for empty arguments
        [[ $# -eq 0  ||  -z $1 ]] && return

        # check for a simple keyword. it should:
        # - contain only letters, numbers, dashes, and dots
        # - not be all digits
        # - not generally begin with a dash, except for e.g. -.mount
        local kw=${@: -1}

        if [[   $kw == *[![:alpha:][:digit:].-]*  ||
                $kw != *[![:digit:]]*  ||
                $kw == -[!.]*  ]]
        then
            # not a keyword
            _args+=( "$@" )

        else
            # keyword found
            _args+=( "${@:1 : $(($#-1)) }" "*${kw}*" )
        fi
    }


    ### Parse command
    local _use_sudo cmd
    cmd=$1
    shift

    # use sudo for system context with non-root user
	if [[  $ctx == --system  &&
           $( id -u ) -ne 0  &&
           $cmd != @(list-*|ls*|find|status) ]]
	then
        _use_sudo=1

	    # prompt for password immediately, if necessary
	    sudo true
    fi

    local _args=() rs cmd_regex
    cmd_regex='^(list-.*|ls.?(-all)?|find)$'

    if [[ $cmd =~ $cmd_regex ]]
    then
        # listing type command
        # ( list-* | ls | ls? | ls-all | ls?-all | find )

        [[ $cmd == *-all ]] &&
            _args+=( --all )

        # expand simple keyword (into _args)
        _expand_keyword "$@"
        shift $#

        # expand command alias
        case $cmd in
            ( ls | lsu | ls-all | lsu-all )
                cmd=list-units
            ;;
            ( lsf | find )
                cmd=list-unit-files
            ;;
            ( lst )
                cmd=list-timers
            ;;
        esac

        # allow return status=1 for nothing found
        _sc_call "$cmd" "${_args[@]}" || {
            rs=$?
            [[ $rs == 1 ]] \
                && return 1 \
                || ( exit $rs )
        }

    else
        # non listing command

        _sc_call "$cmd" "$@"

    fi
}
