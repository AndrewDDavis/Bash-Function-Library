# TODO:
# - do I need both ps-rex and ps-pgrep? try to amalgamate them

ps-rex() (

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : """Display formatted and filtered process list

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
        """
        docsh -TD
        return
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
