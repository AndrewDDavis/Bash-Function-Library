# deps
import_func array_reindex \
    || return 63

# alias for discoverability
alias glob_to_array='array_from_glob'

array_from_glob() {

    : "Expand a glob pattern into an array

        Usage: array_from_glob <array-name> <pattern>

        This function uses \`compgen\` shell builtin to match the glob pattern to file
        paths. Matching paths are written to the designated array variable.

        This function takes care to handle filenames with newlines properly. It does
        this by enforcing that each element of the output array should start with the
        inital path of the glob. If a relative glob pattern does not start with './',
        this is added and removed in intermediate steps, before printing the matches.

        The return status is 0 (true) for at least one match, 1 (false) for no matches,
        or > 1 for an error.
    "

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    (( $# < 3 )) ||
        { err_msg 3 "extra args: '$*'"; return; }

    # defaults and posn'l args
    local -n __res_arr__=${1:?missing array name}
    local pattern=${2:?missing pattern}
    shift 2

    # check pattern for initial /abc or ./
    local bare_ptn abs_rgx glob_init
    abs_rgx='^/[a-zA-Z0-9_ .]*'

    if [[ $pattern =~ $abs_rgx ]]
    then
        glob_init=${BASH_REMATCH[0]}

    else
        glob_init='./'

        if [[ $pattern != ./* ]]
        then
            bare_ptn=1
            pattern=./$pattern
        fi
    fi

    # expand glob
    __res_arr__=()
    mapfile -t __res_arr__ < <( compgen -G "$pattern" )

    # any results?
    [[ -v __res_arr__[*] ]] ||
        return

    # check that all results start with glob_init
    local reidx
    # ( set -x
    for i in "${!__res_arr__[@]}"
    do
        if [[ ${__res_arr__[i]} == $glob_init* ]]
        then
            # for bare pattern, strip search_root
            [[ -v bare_ptn ]] &&
                __res_arr__[i]=${__res_arr__[i]#"$glob_init"}

        else
            # otherwise, there must have been a newline
            __res_arr__[i-1]+=$'\n'${__res_arr__[i]}
            unset '__res_arr__[i]'
            reidx=1
        fi
    done
    # )

    # ensure a contiguous index
    if [[ -v reidx ]]
    then
        array_reindex __res_arr__
    fi

    # older Bash loop code:
    # local fn
    # while IFS= read -r -d '' fn
    # do
    #     # printf '<%s>\n' "$fn"
    #     __res_arr__+=( "$fn" )
    # done < \
    #     <( "${find_cmd[@]}" )
}
