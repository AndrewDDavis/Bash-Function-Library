# dependencies
import_func seqi is_int \
	|| return

time-nits() {

	: "Time a number of repetitions (default 1000) of a command

	Usage: time_nits [-n N] command [args ...]

	Examples

	  time-nits echo hi >/dev/null
	"
	(( $# == 0 )) && set -- '-h'

	# defaults and options
	local -i _n=1000

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

	(( $# > 0 )) || return 2
	is_int -p $_n || return 3

	# defining the array first does not run faster at the fast end, but can prevent
	# random slow results when measuring very short times
	# local i is
	# mapfile -t is < <( seqi "$_n" )
		# for i in "${is[@]}"

	# NB, time writes to STDERR
	local i
	time {
		for (( i=0; i<_n; i++ ))
		do
			"$@"
		done
	}
}
