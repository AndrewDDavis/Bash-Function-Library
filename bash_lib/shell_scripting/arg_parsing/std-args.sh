std-args() {

    : """Group arguments into arrays, setting aside some special ones

        Usage: std-args A1 A2 S1 S2 [-s sf lf [-s ...]] [--] \"\$@\"

        This function populates the A1 and A2 arrays with the option and positional
        arguments passed on the command line, based on the S1 and S2 strings. All four
        positional arguments are required, but S1 and S2 may be empty:

          A1 : array for option flags and their arguments, in the form passed on the
               command line
          A2 : array to hold positional arguments, in their original order
          S1 : string of short options that require an argument, e.g. 'abCD'
          S2 : string of long options that require an argument, seperated by spaces,
               e.g. 'file regexp max-count after-context'

        An array called '_stdopts' is also populated with all option flags and their
        arguments in a standardized form. In particular, blobs of short-option flags are
        individually split, with any argument attached, and long option flags are
        attached to their arguments using '='. The following examples demonstrate the
        four possible option forms in '_stdopts': '-q', '--quiet', '-epattern', and
        '--regex=pattern'.

        This function is most useful for wrapper functions or scripts, in which you want
        to pass the arguments through to another command in their original form, but
        take note of some arguments of special interest, e.g. the patterns to a
        \`grep\` call.

        Due to the nature of this function, it is recommended to issue the '--' argument
        before passing the command-line arguments to be examined.

        Options:

          -s <sf> <lf>
          : Identify an option of special interest. The two string arguments represent
            the short- and long-form option flags. Both arguments are required, but one
            may be empty. This option may be used multiple times.

            Two arrays will be created: 'spec_args' will hold the arguments to special
            flags, and 'spec_idcs' will hold the indices. The format of 'spec_idcs' is
            'i1,i2,i3,...', and the values correspond to the order of the -s flags used
            on the command-line.

            Special option flags should also be included in the S1 and S2 strings passed
            as positional arguments. If flag-only options are of particular interest, it
            is recommended to test the special '_stdopts' array, e.g. with the
            array_match function.

        This function generally allows options to be written on the command line after
        positional arguments. This follows the behaviour of e.g. rsync and GNU grep, in
        which 'grep -e P file1 -i' matches lines with a lowercase or uppercase 'p' from
        a file called 'file1'. In this case, '-e', 'P', and '-i' would be added to the
        option array, and 'file1' to the positional argument array.

        This function also honours the '--' argument to terminate option parsing, and
        adds it to the positional argument array. E.g. in grep, 'grep -- file1 -e P'
        would print 'no such file' errors for '-e' and 'P'. Sensible ways to write the
        command include 'grep -e P -- file1' and 'grep -- P file1'. However, '--' may
        be placed anywhere, as long as no options follow it. Thus, 'grep P -- file1'
        and 'grep P file1 --' work in the same way.

        Example

        # parse grep options, as in _parse_grepopts()
        local so lo opt_arr posarg_arr spec_idcs spec_args _stdopts

        so='efmABCdD'
        lo='max-count label after-context ...'

        std-args opt_arr posarg_arr \"\$so\" \"\$lo\" \\
            -s 'e' 'regexp'  -s 'f' 'file' -- \"\$@\"

        # inspect results
        declare -p opt_arr posarg_arr spec_idcs spec_args _stdopts
    """

    [[ $# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    [[ $# -gt 3 ]] ||
        return 3

    # name-refs to handle opt and posn arg arrays
    local -n opts=$1 pargs=$2
    shift 2

    # short and long option strings for flags that require args
    local sfs=$1 lfs=$2
    shift 2

    ## Special options and associated vars
    # - NB, error on 'declare -n b[1]=a': reference variable cannot be an array.
    # - This limits the options to communicate the info back to the calling function
    #   in a robust and simple way:
    #    1. Output all flags as separate words, with their OPTARGS if applicable, and let
    #       the calling function sort it out as it sees fit.
    #    2. Add the relevent indices for the spec_args array to spec_idcs, following the
    #       order of the -s options given on the CLI.
    # - Doing both: the non-local arrays spec_args and spec_idcs hold the arguments to
    #   special flags and their indices, while _stdopts holds all options and arguments
    #   in a standardized form.
    spec_args=()
    spec_idcs=()
    _stdopts=()

    local sp_sfa sp_lfa
    while [[ ${1-} == -s ]]
    do
        [[ -v 2  && -v 3 ]] ||
            { err_msg 8 "missing argument to -s (sf and lf both required, but may be empty)"; return; }

        [[ -n $2  || -n $3 ]] ||
            { err_msg 9 "need non-empty argument to -s (sf and lf may not both be empty)"; return; }

        sp_sfa+=( "$2" )
        sp_lfa+=( "$3" )
        shift 3
    done

    # -- to terminate std-args option parsing
    [[ ${1-} != '--' ]] ||
        shift

    # convert long flags that require an OPTARG to a pattern string, as in
    # "foo|bar|baz", after word-splitting
    local lf_pat lf_words
    if [[ -z $lfs ]]
    then
        lf_pat=''
    else
        read -ra lf_words -d '' < <( printf '%s\0' "$lfs" )
        lf_pat=$( str_join_with '|' "${lf_words[@]}" )
    fi

    # clear opt and posn arg arrays
    opts=()
    pargs=()

    # loop over arguments
    # - NB, test -v tests that $1 is set (may be empty)
    local i
    while [[ -v 1 ]]
    do
        case $1 in

            ( [!-]* | - )
                # positional arg
                pargs+=( "$1" )
                shift
            ;;

            ( -- )
                # terminate option parsing
                pargs+=( "$1" )

                # all following args are positional args
                [[ -v 2 ]] &&
                    pargs+=( "${@:2}" )

                shift $#
            ;;

            ( --* )
                # long option:
                # - long options that don't require an arg can be passed through
                # - long options that require an arg, and are given as --key=value,
                #   can be passed through, but capture any patterns
                # - long options that require an arg, and are given as --key, should
                #   be passed through with the following arg, and note any patterns

                if [[ ${1#--} == @($lf_pat) ]]
                then
                    # long options that require an arg, and are alone
                    # - this includes regexp and file (now)
                    # - note the arg to --colo[u]r is optional, so it's handled below

                    # check for special flags
                    for i in "${!sp_sfa[@]}"
                    do
                        [[ -n ${sp_lfa[i]}  &&  ${1#--} == "${sp_lfa[i]}" ]] && {

                            spec_idcs[i]+=",${#spec_args[@]}"
                            spec_args+=( "$2" )
                            break
                        }
                    done

                    opts+=( "$1" "$2" )
                    _stdopts+=( "${1}=${2}" )
                    shift 2
                else
                    # other long option flags, like --ignore-case, and args that
                    # have both the flag and the arg, like --label=foo

                    [[ $1 == *=* ]] && {

                        # check for special flags
                        for i in "${!sp_sfa[@]}"
                        do
                            [[ -n ${sp_lfa[i]}  && ${1%%=*} == "--${sp_lfa[i]}" ]] && {

                                spec_idcs[i]+=",${#spec_args[@]}"
                                spec_args+=( "${1#*=}" )
                                break
                            }
                        done
                    }

                    opts+=( "$1" )
                    _stdopts+=( "$1" )
                    shift
                fi
            ;;

            ( -* )
                # short option:
                # - short option blobs with only flag options are safe to pass through
                # - short option blobs with OPTARG options in the middle are safe
                #   to pass through, but capture any patterns
                # - short option blobs with OPTARG options at the end should be
                #   passed through with the following arg, and note any patterns

                # match with anchored regex patterns
                # - or match using [[ ... == ... ]] that allows extglob, e.g. +([$sfs])
                # - however [[ ... =~ ... ]] produces BASH_REMATCH array, which is useful

                if [[ -z $sfs ]]
                then
                    # no short flags need args
                    opts+=( "$1" )
                    shift

                elif [[ $1 =~ ^-([^$sfs]*)([$sfs])$ ]]
                then
                    # blobs that need the next arg for the OPTARG, like '-e' or '-ie'

                    # check for special flags
                    for i in "${!sp_sfa[@]}"
                    do
                        [[ ${BASH_REMATCH[2]} == "${sp_sfa[i]}" ]] && {

                            spec_idcs[i]+=",${#spec_args[@]}"
                            spec_args+=( "$2" )
                            break
                        }
                    done

                    while [[ -n ${BASH_REMATCH[1]} ]]
                    do
                        _stdopts+=( "-${BASH_REMATCH[1]:0:1}" )
                        BASH_REMATCH[1]=${BASH_REMATCH[1]:1}
                    done

                    _stdopts+=( "-${BASH_REMATCH[2]}${2}" )

                    opts+=( "$1" "$2" )
                    shift 2
                else
                    # other blobs that don't need args, like '-iq', and blobs that
                    # include the OPTARG after the flag, like '-efoo'
                    local optarg

                    # NB, safe blobs match against [[ $1 =~ ^-([^$sfs]+)$ ]]
                    # - match an inclusive pattern, then test BASH_REMATCH elements
                    [[ $1 =~ ^-([^$sfs]*)(([$sfs]).+)?$ ]]

                    while [[ -n ${BASH_REMATCH[1]} ]]
                    do
                        _stdopts+=( "-${BASH_REMATCH[1]:0:1}" )
                        BASH_REMATCH[1]=${BASH_REMATCH[1]:1}
                    done

                    [[ -n ${BASH_REMATCH[2]} ]] && {

                        # check for special flags and capture the OPTARG
                        optarg=${1#-*"${BASH_REMATCH[3]}"}

                        for i in "${!sp_sfa[@]}"
                        do
                            [[ ${BASH_REMATCH[3]} == "${sp_sfa[i]}" ]] && {

                                spec_idcs[i]+=",${#spec_args[@]}"
                                spec_args+=( "$optarg" )
                                break
                            }
                        done

                        _stdopts+=( "-${BASH_REMATCH[2]}" )
                    }

                    opts+=( "$1" )
                    shift
                fi
            ;;
        esac
    done

    # trim initial ',' from spec_idcs
    for i in "${!spec_idcs[@]}"
    do
        spec_idcs[i]=${spec_idcs[i]/#,/}
    done
}

