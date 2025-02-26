# Process listing using Linux ps and pgrep from the procps package

# TODO:
# - do I need both ps-rex and ps-pgrep?
# - try to amalgamate them

# pgrep matches pattern against commands, outputs pids 1 per line
#   pgrep [opts] <ERE pattern>
#   -f : match against full command line
#   -l : show process name as well as PID
#   -a : show full command line as well as PID
# - See other notable options in the ps-pgrep function below.
# e.g. pgrep -lf daemon
alias pgrep-fl='pgrep -fl'
alias pgrep-fa='pgrep -fa'

ps-rex() (

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Display formatted and filtered process list

        Usage

          ps-rex [ps-opts ...] [fmt_code] <pattern>

        The pattern is interpreted as an ERE expression, and must be the last
        argument. To prevent the pattern from filtering any processes (i.e. show
        all processes), '^' may be used as the pattern.

        The fmt_code argument may be used to control the ouput format according to
        a few recommended defaults. Alternatively, options like -f, -ly, or -o may
        be used in the typical way for ps.

        Possible values of fmt:

          tug : compact start time, user, and group
          cmd : pid and ppid with full command line
          cup : pid, ppid, user, and group info with full command line
          cut : pid, ppid, user, and start time with full command line
          stg : process group, session, and state info

        Options provided on the command line are passed to ps, and generally fall under
        one of two types:

        1. Options that select the processes to display (before filtering with
           the pattern). If none of these are given, ps selects the processes of
           the calling user and terminal.

           -e     : show all processes (synonym -A)
           -u     : processes of a user
           -g     : processes of a group
           -s x,y : processes of a session list
           -t     : processes of a tty
           -C     : processes matching a command name
           -p     : select process by pid list (e.g. \"1 2\" or 1,2)
           --ppid : select process by ppid list

        2. Options that control the output format (columns, sorting).

           -f     : display info in 'full' format. This has many effects that don't seem
                    to be full documented, e.g. causes cmd rather than comm, shows tree
                    view like --forest, but also shows processes from all TTYs, not just
                    the current one.
           -l     : display in 'long' format
           -y     : no flags, rss in place of addr; used with -l
           -o fmt : define output format
           -H     : tree view, but uses only indentation, not ascii art. Conflicts with
                    -f, although --forest does not.
           --forest : show ascii-art tree view

        Examples

          # filter all processes, output in full format
          ps-rex -ef foo

          # same, with long format
          ps-rex -ely foo

        Rough notes

        - info/columns that would be nice/useful: S,PRI,NI,RSS,lstart,user,group
        - when using grep or sed to search, escape or bracket a char to prevent needing grep -v (e.g. sea\rchterm, [s]earchterm)
        "
        return 0
    }

    # capture pattern and remove it from args
    local pat

    if [[ $# -eq 1 ]]
    then
        pat=$1
        shift

    else
        pat=${@:(-1)}
        set -- "${@:1:$#-1}"
    fi

    # if a format code was specified, translate it to ps format
    local ofmt

    case ${@:(-1)} in
        ( args | cmd )
            ofmt="pid,ppid,args"
        ;;
        ( tug )
            ofmt="pid,comm,user,group,lstart"
        ;;
        ( cup )
            ofmt="user,group,supgrp,pid,ppid,state,start,cmd"
        ;;
        ( cut )
            ofmt="user,pid,ppid,state,start,cmd"
        ;;
        ( stg )
            ofmt="stat,tty,sess,pgid,ppid,pid,comm -H --forest"
        ;;
    esac

    if [[ -n ${ofmt:-} ]]
    then
        # remove ofmt arg from posn params
        if [[ $# -eq 1 ]]
        then
            shift
        else
            set -- "${@:1:$#-1}"
        fi

        set -- "$@" -o "$ofmt"
    fi

    # Run ps and capture the output to filter
    ps_out=$( set -x; ps "$@" )

    # Use sed for regex search (like egrep) but preserve the header
    # - NB, if i always remembered to add [] around 1 char, I wouldn't need the
    #   extra filter...
    sed_script="1 { p; d; }
                / sed -nE 1 p/ d
                /${pat}/ p
               "
    filtered_out=$( sed -nE "$sed_script" <<< "$ps_out" )

    # Output result if anything found
    lc=$( grep -c '^' <<< "$filtered_out" )

    if [[ $lc -gt 1 ]]
    then
        # if necessary, can truncate output with e.g. cut -c -$( tput cols )
        printf '%s\n' "$filtered_out"
    else
        echo "Nothing found. Remember to use '-e' to search all processes."
    fi
)

ps-pgrep() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

	    docsh -TD "Combine ps and pgrep to view info for selected processes

            Usage: ps-pgrep [options] <ERE pattern>

            First, ps-pgrep passes the pattern argument and any options provided
            to \`pgrep\`, to obtain PIDs. Then the pids are passed to \`ps\`, to show
            info about the processes.

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
	    return 0
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
    local _v ps_cmd pgrep_cmd grep_cmd

    ps_cmd=$( type -P ps )
    pgrep_cmd=$( type -P pgrep )
    grep_cmd=$( type -P grep )

    if ! {
        _v=$( "$ps_cmd" --version 2>/dev/null ) &&
            "$grep_cmd" -q 'procps-ng' <<< $_v
        }
    then
        err_msg 2 "ps version not supported; \`type ps\` says:
                   $( type ps | head -1 )"
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
