# TODO:
# - do I need both ps-rex and ps-pgrep? try to amalgamate them

ps-pgrep() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

	    : "List selected processes and info using ps and pgrep commands

            Usage: ps-pgrep [options] <ERE pattern>

            Both ps and pgrep from the procps package are used. First, the pattern
            argument and any command-line options are passed to \`pgrep\`, to obtain
            PIDs. Then the pids are passed to \`ps\` to show info about the processes.

            The pattern is matched as an ERE in a case insensitve manner, against the
            whole command line. To match only a command name, use an anchored regex
            pattern, e.g. '^lf', '^lf( |$)', or '\blf\b'.

            Options issued to \`pgrep\` by default:

              -A  : filter out all ancestors of pgrep, pkill, or pidwait (useful e.g.
                    when running with sudo)
              -i  : case insensitive matching
              -f  : match against full command line (cancelled by -C, see below)
              -d, : delemit PIDs with a comma, rather than newline (for input to \`ps\`)

            Options interpreted by ps-pgrep:

              -C : match command name only (cancels pgrep -f)

            Other notable \`pgrep\` options:

              -x           : require exact match to search pattern
              -o / -n      : select only the oldest or newest matching process (most/least recently started)
              -g / -u / -P : match only a process group, user, PPID, runstate, etc

            \`ps\` output options issued by default:

              -f : full-format listing

            Other Notes:

            - Only Linux ps (procps) is supported, macOS/BSD ps syntax is different.


            TODO:
            - output format options with --ofmt

                eo         : show every process in a basic format
                gr <gid>   : show process groups matching gid
                f1         : show process hierarchy (forest)
                f2         : show forest with ASCII art

                TODO: support 'ps -C' to select commands by name, -G, ...

            - introduce -k or --signal option to kill processes or send other signal once you have the
                  list you want
              -k [sig] : send signal to processes (default TERM, see /usr/bin/kill -L for a list)
        "
        docsh -TD
	    return
    }

    # pgrep defaults
    local pgrep_opts=( '-Aif' '-d,' )

    # ps output defaults
    local ps_opts=( '-f' )

    # ps output formats
    # TODO
        #     ( eo )
        #     ps -eo pid,ppid,uid,s,command
        # ;;
        # ( gr )
        #     gid=$1
        #     pg_pids=$( pgrep -d ',' -g "$gid" )
        #     ps -o pid,pgid,command -p "$pg_pids"
        # ;;
        # ( f1 )
        #     ps -eHo pid,pgid,uid,s,command
        # ;;
        # ( f2 )
        #     ps -eo pid,pgid,uid,s,comm --forest
        # ;;

    ### Parse arguments






    ### check for supported ps
    local _v ps_cmd pgrep_cmd

    ps_cmd=$( builtin type -P ps )
    pgrep_cmd=$( builtin type -P pgrep )

    if ! {  _v=$( "$ps_cmd" --version 2>/dev/null ) \
                && [[ $_v == *procps-ng* ]]; }
    then
        err_msg 2 "ps version not supported; \`type ps\` says:
                   $( builtin type ps | head -1 )"
                   # ^^^ uses head to prevent printing of function definition
        return
   fi

    ## get pids
    # - pgrep exits with code 1 if nothing found
    local pids ps_out

    if pids=$(
        set -x
        "$pgrep_cmd" "${pgrep_opts[@]}" "$@"
        )
    then
        ## report
        # - uses '-p' to select processes by PID
        ps_out=$(
            set -x
            "$ps_cmd" "${ps_opts[@]}" -p "$pids"
        )
        printf '\n' >&2
        printf '%s\n' "$ps_out"
    else
        printf '\n%s\n' "No matches." >&2
    fi
}
