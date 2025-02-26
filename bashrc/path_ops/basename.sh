#!/usr/bin/env bash

__version__="\
basename function v0.1 (Feb 2025)
by Andrew Davis
"

basename() {

    : "Strip leading directories and suffix from file paths

    Usage

        basename [options] <path> [ suffix | path ... ]

    This shell function implementation of the basename command prints each path after
    removing any leading directory components and any trailing slashes. If a suffix is
    specified, it is also removed. The suffix is interpreted as a fixed string. The
    reference implementation of this command is GNU basename.

    The first positional argument is always interpreted as a path. By default, the next
    positional argument is interpreted as a suffix, but this behaviour is modified by
    -a and -s. It is an error to pass more than 2 positional arguements without using
    -a or -s.

    Options

      -a (--multiple)
      : allow multiple positional arguments, and treat them as paths

      -s (--suffix) <suffix>
      : specify a trailing suffix to remove, and enable -a

      -z (--zero)
      : end each output line with NUL, not newline

      -h (--help)
      : display this help and return

      --version
      : output version information and return

    Examples

      basename /usr/bin/sort
      # sort

      basename include/stdio.h .h
      # stdio

      basename -s .h include/stdio.h
      # stdio

      basename -a any/str1 any/str2
      # str1
      # str2
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

	# long options can be handled better when getopts_long is ready
	local i
	for (( i=1; i<=$#; i++ ))
	do
    	case ${!i} in
    	    ( -- ) break ;;
    	    ( --version ) printf '%s\n' "$__version__"; return ;;
    	    ( --zero | --suffix | --multiple )
    	        err_msg 3 "long opts not implemented"
    	        return
    	    ;;
        esac
	done

    # defaults
    local _ot='\n' _a _s

    local flag OPTARG OPTIND=1
    while getopts ':as:z' flag
    do
        case $flag in
			( a | multiple )
			    _a=1 ;;
			( s | suffix )
			    _s=$OPTARG ;;
			( z | zero )
			    _ot='\0' ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    if [[ $# -eq 0 ]]
    then
        err_msg 3 "missing path"
        return

    elif [[ -z ${_a-}  && -z ${_s-}  && $# -gt 1 ]]
    then
        if [[ $# -gt 2 ]]
        then
            err_msg 3 "extra positional argument: ${*:3:1}"
            return
        else
            # 2nd pos'l arg interpreted as suffix
            _s=$2
            set -- "$1"
        fi
    fi

    local pth spth bn
    for pth in "$@"
    do
        # spth is path stripped of trailing slashes
        spth=${pth%/}
        while [[ ${spth:(-1)} == '/' ]]
        do
            spth=${spth%/}
        done

        if [[ $pth == +('/') ]]
        then
            # special case
            bn='/'

        elif [[ $spth != *[/]* ]]
        then
            # filename in CWD
            bn=$spth

        elif [[ ${spth:1} != *[/]* ]]
        then
            # root path, e.g. /etc
            bn=${spth:1}

        else
            bn=${spth##*/}
        fi

        # strip trailing suffix
        # - match GNU basename behaviour, don't produce empty bn
        [[ -n ${_s-}  && $bn == *?"$_s" ]] &&
            bn=${bn%"${_s}"}

        printf '%s'"$_ot" "$bn"
    done
}
