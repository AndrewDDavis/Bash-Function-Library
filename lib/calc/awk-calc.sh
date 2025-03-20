awk-calc() {

    : "Print result of calculation using awk

    Usage: awk-calc [options] <expression>

    Options

      -v <var=value>
      : Set variables to be referenced in the expression. May be used multiple times.

      -f <fmt>
      : Set format string of the output for printf. By default, '%.6g', unless the
        result is an exact integer.

    Example

      # cube of 2
      awk-calc '2^3'

      # integer-rounded result of 7/3
      awk-calc -f '%.0f' -v 'a=3' -v 'b=7' 'b/a'
    "
    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local _fmt='%.6g' awkopts=()

    local OPTARG OPTIND=1 flag
	while getopts ':f:v:' flag
	do
		case $flag in
			( f )
				_fmt=$OPTARG
			;;
			( v )
				awkopts+=( -v "$OPTARG" )
			;;
			( \? )
		    	err_msg 2 "unknown option: '$OPTARG'"
		    	return
			;;
			( : )
		    	err_msg 2 "missing argument for -$OPTARG"
		    	return
			;;
		esac
	done
	shift $(( OPTIND-1 ))

    [[ $# -gt 0 ]] ||
        { err_msg 2 "missing expression"; return; }

    command awk "${awkopts[@]}" \
        -v "_fmt=$_fmt" \
        "BEGIN {
            OFMT = _fmt
            print $*
        } "
}
