str_split() {

    [[ $# -eq 0  || $1 == @(-h|--help) ]] && {

        : "Split string into array elements

        Usage: str_split [-d delim] <array-name> [string]

        This function populates the elements of the array by splitting the supplied
        string. By default, or when delim is the empty string, each element corresponds
        to a single character from the string. If no string is supplied on the command
        line, STDIN is used.

        Options

          -d delim : split string at each instance of delim
          -q       : suppress warning when array is not empty

        Examples

          str_split str_elems 'each_char_is_an_elem'
          str_split -d '/' path_elems 'path/to/split'
        "
        docsh -TD
        return
    }

    # verbosity
    local _v=1 _d=''

    local flag OPTARG OPTIND=1
    while getopts ':d:q' flag
    do
        case $flag in
            ( d ) _d=$OPTARG ;;
            ( q ) (( _v-- )) ;;
            ( \? ) err_msg 2 "unknown option: '-$OPTARG'"; return ;;
            ( : )  err_msg 2 "missing argument for -$OPTARG"; return ;;
        esac
    done
    shift $(( OPTIND-1 ))

    # nameref to the array variable
    local -n _ss_arr=$1 || return
    shift

    # read stdin if necessary
    # - don't be tempted to use $( < /dev/stdin ), as [noted](https://unix.stackexchange.com/a/716439/85414)
    [[ $# -eq 0 ]] &&
        set -- "$( cat )"

    # clear the array
    [[ $_v -gt 0 ]] && {
        # - check array and warn
        # - avoiding unbound variable on ${#_ss_arr[@]}
        [[ -n ${_ss_arr[*]} ]] &&
            err_msg w "clearing non-empty array '${!_ss_arr}'"
    }
    _ss_arr=()


    # Safely populate the array
    if [[ -z $_d ]]
    then
        # Split string into individual characters
        local -i i
        for (( i=0; i<${#1}; i++ ))
        do
            _ss_arr+=( "${1:i:1}" )
        done

    elif [[ -n $( command -v mapfile ) ]]
    then
        # Use the mapfile builtin (AKA readarray in newer Bash)
        # - Nulling IFS is necessary to prevent stripping of leading and trailing
        #   whitespace in the fields.
        IFS='' mapfile -td "$_d" _ss_arr < \
            <( printf '%s' "$1" )

    else
        # Use read in classic Bash
        IFS="$_d" read -r -d '' -a _ss_arr < \
            <( printf '%s\0' "$1" )
    fi
}
