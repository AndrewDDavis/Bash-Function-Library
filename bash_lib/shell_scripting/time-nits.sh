# dependencies
import_func seqi \
	|| return

time-nits() {

	: "Time a number of repetitions (default 1000) of a command

	Usage: time_nits [-n N] command [args ...]

	Examples

	  time-nits echo hi >/dev/null
	"
	(( $# == 0 )) && set -- '-h'

	# defaults and options
	local _n=1000

	local flag OPTARG OPTIND=1
	while getopts ':n:h' flag
	do
		case $flag in
			( n ) _n=$OPTARG ;;
			( h ) docsh -TD; return ;;
			( : )  err_msg 2 "missing argument for option $OPTARG"; return ;;
			( \? ) err_msg 3 "unknown option: '$OPTARG'"; return ;;
		esac
	done
	shift $(( OPTIND-1 ))

	(( $# == 0 )) && return 2

	local i is
	mapfile -t is < <( seqi "$_n" )

	# NB, time writes to STDERR
	time {
		for i in "${is[@]}"
		do
			"$@"
		done
	}
}
