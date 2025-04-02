calc-awk() {

    : "Print result of math expression using awk

    Usage: calc-awk [options] <expression>

    Options

      -v <var=value>
      : Set variables to be referenced in the expression. May be used multiple times.

      -f <fmt>
      : Set format string of the output for printf. By default, '%.6g', unless the
        result is an exact integer.

      -i
      : Format output as integer.

    Examples

      # cube-root of 12, with precision of 3
      calc-awk -f '%.3f' '12^(1/3)'

      # integer-rounded result of 7/3
      calc-awk -i -v 'a=3' -v 'b=7' 'b/a'
    "

    # defaults and option parsing
    local _fmt='%.6g' awk_cmd

    awk_cmd=( "$( builtin type -P awk )" ) \
        || return 9

    local flag OPTARG OPTIND=1
	while getopts ':v:f:ih' flag
	do
		case $flag in
			( f )
				_fmt=$OPTARG
			;;
			( v )
				awk_cmd+=( -v "$OPTARG" )
			;;
			( i )
				_fmt='%.0f'
			;;
			( h )
                docsh -TD
                return
			;;
			( \? )
		    	err_msg 2 "unknown option: '-$OPTARG'"
		    	return
			;;
			( : )
		    	err_msg 3 "missing argument for -$OPTARG"
		    	return
			;;
		esac
	done
	shift $(( OPTIND-1 ))

    awk_cmd+=( -v "_fmt=$_fmt" )

    (( $# > 0 )) ||
        { err_msg 4 "missing expression"; return; }

    (( $# == 1 )) ||
        { err_msg 5 "too many arguments: ${*@Q}"; return; }

    # script
    # - NB, awk lacks the ability to evaluate a string variable as an expression,
    #   so expand the variable directly into the script
    local ascr="
        BEGIN {
            OFMT = _fmt
            print $1
        }
    "

    "${awk_cmd[@]}" "$ascr"
}
