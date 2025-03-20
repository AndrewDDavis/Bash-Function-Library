__version__="\
dirname function v0.1 (Feb 2025)
by Andrew Davis
"

dirname() {

    : "Strip last component from a file path

    Usage: dirname [option] <path> ...

    This shell function implementation of the dirname command prints each path after
    removing the last non-slash component and any trailing slashes. If the path does
    not contain '/', it prints '.', representing the current directory. The reference
    implementation of this command is GNU dirname.

    Options

      -z (--zero)
      : end each output line with NUL, not newline

      -h (--help)
      : display this help and return

      --version
      : output version information and return

    Examples

      dirname /usr/bin/
      # /usr

      dirname dir1/str dir2/str
      # dir1
      # dir2

      dirname stdio.h
      # .
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

	# long options can be handled better when getopts_long is ready
	case $1 in
	    ( --version ) printf '%s\n' "$__version__"; return ;;
	    ( --zero ) set -- '-z' "${@:2}" ;;
    esac

    # defaults
    local _ot='\n'

    local flag OPTARG OPTIND=1
    while getopts ':z' flag
    do
        case $flag in
			( z | zero )
			    _ot='\0' ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    local pth spth dn
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
            dn='/'

        elif [[ $spth != *[/]* ]]
        then
            # CWD path
            dn='.'

        elif [[ ${spth:1} != *[/]* ]]
        then
            # root path, e.g. /etc
            dn='/'

        else
            dn=${spth%/*}
        fi

        printf '%s'"$_ot" "$dn"
    done
}
