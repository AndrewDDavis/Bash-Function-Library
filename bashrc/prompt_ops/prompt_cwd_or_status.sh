prompt_cwd_or_status () {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        : "Print string for PS1, testing return status of previous command

        Usage: prompt_cwd_or_status \$?
        "
        docsh -TD
        return
    }

    # return status
    local retstat=$1 || return
    shift

    # generate shortened CWD string
    local scwd=$( shrtn_cwd )

    if [ $retstat = 0 ]
    then
        # just print the string
        # - newline is stripped when output is captured
        # - don't prepend with any reset, as colour is set in prompt_colourize
        printf '%s\n' "$scwd"

    else
        # print return status instead of CWD
        # - length of status string should be the same as shrtn_cwd would return
        # - pad internally with spaces to prevent them getting stripped on return

        # Define variables for control sequence codes
        # - these CSI codes must be evaluated using printf's %b, since this function writes
        #   into PS1 after they would be interpreted
        # - for the same reason, not using the -p option here, but must wrap the control
        #   sequences in \001 and \002, since \[ and \] won't be interpreted (as noted at
        #   the [bash faq](https://mywiki.wooledge.org/BashFAQ/053)).
        # - this is easily accomplished using the -d option to str_csi_vars
        # - another way is to use the variable transformation @P to print a string "like a
        #   prompt", e.g. 'echo "${foo@P}"', which will evaluate escape sequences _and_
        #   \[...\], unlike printf '%b' ... .

        # - these may be defined by a run in prompt_colourize; skip if so
        [[ -z ${_cbo-} ]] && str_csi_vars -pd


        # number of extra chars in short-cwd vs ret-status
        local n_xchr=$(( ${#scwd} - ${#retstat} ))

        # prepend return status value with a string that provides context
        # - could use a no-break space ($'\u00A0') in places where a regular one would
        #   get stripped away; doesn't seem to be an issue
        local ststr c

        if   [[ $n_xchr -lt 1 ]]; then { ststr=""  ; c=0; }
        elif [[ $n_xchr -eq 1 ]]; then { ststr="?" ; c=1; }
        elif [[ $n_xchr -lt 7 ]]; then { ststr="?:"; c=2; }
        else { ststr="status:"; c=7; }
        fi

        # decrement no. of extra chars
        n_xchr=$(( $n_xchr - $c ))

        # apply prepend string using colours and bold
        if [[ -n $ststr ]]
        then
            # make the pre-string red, except the colon if there was one
            c=''
            [[ $ststr == *: ]] && c=':'

            ststr="${_cbo}${_cfg_r}${ststr%:}${_crs}${c}${_cbo}${retstat}${_crs}"
        else
            # if there's no extra space, just red-bold the return status
            ststr="${_cbo}${_cfg_r}$retstat${_crs}"
        fi

        # pad with spaces as necessary, accounting for [ ... ]
        local _add_br
        [[ $n_xchr -gt 3 ]] && {

            n_xchr=$(( $n_xchr - 4 ))
            _add_br=1
        }

        [[ $n_xchr -gt 0 ]] && {

            # split spaces front and back, checking for odd
            local fs=$(( ${n_xchr}/2 + ${n_xchr}%2 ))
            local bs=$(( ${n_xchr}/2 ))

            # string of spaces to pull from
            local i s=''
            for i in $(seq $fs); do s="$s "; done

            ststr="${s::$fs}${ststr}${s::$bs}"
        }

        # wrap in [ ... ] if indicated
        [[ -n ${_add_br-} ]] && ststr="${_cbo}[${_crs} ${ststr} ${_cbo}]${_crs}"

        # print status string, prepending a reset
        printf "%s%s\n" "$_crs" "$ststr"
    fi
}
