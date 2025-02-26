shrtn_cwd() (

    [[ $# -gt 0 && $1 == @(-h|--help) ]] && {

        : "Shorten the working directory path for use in the PS1 prompt string.

	    Usage: shrtn_cwd [options ...]

	    - Resolves symlinks, uses ~, and truncates in a sensible place, respecting
	      PROMPT_DIRTRIM if optimal.
	    - This function takes ~ 15 ms to execute with a long path on a modest machine.
	    - Uses canonical CWD path (as in cd -P)


        Options

	      -n <d> : set limit to \`d\` characters; the default is 20% of the terminal
	               width to a max of 24 chars, or 12 if the width is unknown
	          -b : shorten only the basename, rather than the whole path
              -r : CWD path is relative to symbolic links, rather than canonical,
                   as in 'cd -P')

	    Example

	      shrtn_cwd -n 12 -b
        "
        docsh -TD
        return
    }

    # Defaults
    local bw=w      # basename or whole path
    local rc=c      # relative or canonical CWD

    # default max string length: 20% of screen or 24 columns
    local clim

    if [[ -n ${COLUMNS-} ]]
    then
        clim=$(( COLUMNS/5 ))

    elif [[ -n $( command -v tput ) ]]
    then
        clim=$(( $( tput cols )/5 ))

    else
        clim=12
    fi

    [[ $clim -gt 24 ]] && clim=24


    # Parse args
    local flag OPTARG OPTIND=1

    while getopts "n:br" flag
    do
        case $flag in
            ( n ) clim=$OPTARG ;;
            ( b ) bw=b ;;
            ( r ) rc=r ;;
            ( \? | : ) return 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ))


    # Get CWD path and basename
    local swd

    if [[ $rc == c ]]
    then
        # use canonical path
        # dirs builtin uses ~ notation when returning CWD
        swd=$( builtin cd -P "$PWD" 2>/dev/null &&
                   builtin dirs +0 )
    else
        # use relative path
        swd=$( builtin dirs +0 2>/dev/null )
    fi

    # sanity check: e.g. for when under a mount point that got disconnected
    [[ -n ${swd-} ]] || return 2

    # Basename
    local swd_bn=$( basename "$swd" )


    ### Shorten according to settings

    if [[ $swd == '/' ]]
    then
        # root dir is a special case
        true

    elif [[ $bw == b  ||  ${#swd_bn} -gt $(( $clim - 5 )) ]]
    then
        # Only basename considered if requested, or swd is already long
        # - clim needs a bit of padding in the above comparison to account for '.../'
        swd=$( str_trunc $clim "$swd_bn" )

    elif [[ $bw == w ]]
    then
        # Whole path considered
        # if DIRTRIM is set, respect it
        [[ -n ${PROMPT_DIRTRIM-} ]] && {

            # create array from path elements
            local swd_arr

            IFS="/" read -ra swd_arr <<< "${swd#/}"  # split at /, omitting root dir

            # keep DIRTRIM dirs in addition to ~/ and /, as the shell would
            [[ ${swd_arr[0]} == \~ ]] && unset swd_arr[0]

            [[ "${#swd_arr[@]}" -gt $PROMPT_DIRTRIM ]] && {

                # remove everything before trim_dir
                local trim_dir=${swd_arr[-$PROMPT_DIRTRIM]}

                swd="${trim_dir}/${swd#*/${trim_dir}/}"
            }
        }

        # truncate as necessary
        (( ${#swd} > $clim )) && {

            # shorten the leading path; account for basename, then add it back
            local -i n=$(( $clim - ${#swd_bn} ))
            swd=$( str_trunc -s $n "${swd%${swd_bn}}" )
            swd=${swd}${swd_bn}
        }
    fi

    printf '%s\n' "$swd"
)
