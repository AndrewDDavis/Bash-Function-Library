# deps
import_func alias-resolve array_strrepl \
    || return 63

# Smart-case egrep
alias egreps="greps -E"

greps() {

    : "Smart-case matching with grep

    Usage

        greps [opts] <pattern> [file1 or - ...]
        greps [opts] -e <pattern1> ... [file1 or - ...]

    This wrapper function passes almost all of its arguments straight through to the
    local \`grep\` command, and can generally be used as a replacement. It introduces
    \"smart-case\" matching, as seen e.g. in the 'less' pager: the pattern matching is
    case-insensitive for lower-case search patterns, but case-sensitive if the pattern
    includes non-escaped uppercase letters.

    The smart-case functionality can be disabled using the --case-sensitive option. It
    is also disabled if the -i, --ignore-case, or --no-ignore-case options are used. The
    comments of this function's code contain a comparison of options relevant to
    case-sensitive matching across various grep tools.
    "

    [[ $# -eq 0  ||  $1 == @(-h|--help) ]] &&
        { docsh -TD; return; }

    # inherit verbosity, if any
    local -I _v
    [[ -n ${_v-} ]] ||
        _v=1

    # use full patch to grep, but also keep any defined alias
    local grep_cmd grep_path

    grep_path=$( builtin type -P grep ) \
        || return

    alias-resolve -e grep grep_cmd \
        || grep_cmd=( grep )

    array_strrepl grep_cmd grep "$grep_path"


    # GNU grep arg-parsing behaviour:
    # - grep patterns come from the first positional arg, or are given with the -e flag,
    #   possibly multiple times, or -f gives patterns from file
    # - if the pattern is given with -e, all positional args are treated as files
    # - -e 'pat' may also be written as --regexp='pat' or --regexp 'pat'

    # Use _parse_grepopts to parse the arguments as grep would
    # - this function will need the _stdopts array to check for -i, and an array of
    #   pattern arguments to check for uppercase patterns
    local gopts gargs gpats _stdopts

    _parse_grepopts gopts gargs gpats "$@" \
        || return


    # Enable smart-case by default
    local _i=1

    # Relevant options around case across grep tools:
    #
    #   - gnu grep:
    #     -i (--ignore-case), --no-ignore-case
    #     uses -s for --no-messages, nothing on -S, -j, or -J
    #   - BSD grep:
    #     -i (--ignore-case)
    #     uses -s for --no-messages, -S for follow symlinks, -J for bz2decompress,
    #     nothing on -j; --no-ignore-case does NOT work
    #   - ripgrep:
    #     -i (--ignore-case), -S (--smart-case), -s (--case-sensitive);
    #     uses -j for --threads, nothing on -J; --no-ignore-case does NOT work
    #   - ugrep:
    #     -i (--ignore-case), --no-ignore-case, -j (--smart-case);
    #     uses -s for --no-messages, -S for --dereference-files, and -J for --jobs

    [[ ${#gopts[@]} -gt 0 ]] && {

        # Check for --case-sensitive, -i, etc. in gopts and _stdopts
        local n

        if n=$( array_match -nF gopts '--case-sensitive' )
        then
            _i=''
            unset "gopts[$n]"

        elif array_match _stdopts '-i|--ignore-case|--no-ignore-case'
        then
            _i=''
        fi
    }

    [[ -n ${_i-} ]] && {

        # enact smart case by checking for uppercase in patterns
        # - if no upper-case letters, then do case-insensitive matching
        # - *[[:upper:]]* is nice and simple, but misses regex elements like \W
        # - Could also do [[ $pat == [[:upper:]]* || $pat == *[!\\][[:upper:]]* ]], but
        #   it doesn't seem to make much difference: time reports both that and the
        #   regex variant below take 0.000s for a short string match.
        local p

        for p in "${gpats[@]}"
        do
            [[ $p =~ (^|[^\\])[[:upper:]] ]] && {

                # non-escaped uppercase found: use case sensitive match
                _i=''
                break
            }
        done
    }

    [[ -n ${_i-} ]] &&
        gopts+=( -i )

    (
        [[ _v -gt 1 ]] && set -x
        "${grep_cmd[@]}" "${gopts[@]}" "${gargs[@]}"

    ) || return     # can be normal grep rs=1
}


_parse_grepopts() {

    : "Keep command-line argument blobs intact while identifying pattern arg(s)

    Usage: _parse_grepopts opt_arr posarg_arr pattern_arr \"\$@\"

    This function uses std-args to parse its arguments in the same way as grep. It
    returns arrays containing the options and positional arguments, as well as an arry
    of patterns. The _stdopts array is also created, which contains all options and
    their arguments in a standardized form (refer to std-args()).

    The behaviour of GNU grep is replicated. In particular:

      - All positional args are treated as filenames rather than patterns, if a pattern
        was provided by -e, --regexp, -f or --file.
      - Options may be issued after positional arguments, unless the '--' argument is
        used to terminate option parsing.
    "

    # name-refs to handle the arrays
    local -n _opts=$1 _posargs=$2 _pats=$3
    shift 3

    # call std-args with the list of flags that need args, and noting pattern flags
    # - this clears and sets _opts and _posargs
    local spec_idcs spec_args

    local sf='efmABCdD'
    local lf='regexp file max-count label
              after-context before-context context
              group-separator binary-files devices directories
              exclude exclude-from exclude-dir include'

    std-args _opts _posargs "$sf" "$lf" \
        -s 'e' 'regexp'  -s 'f' 'file' -- "$@" \
        || return

    # check for patterns or pattern files
    _pats=()

    if [[ ${#spec_args[@]} -eq 0 ]]
    then
        # no patterns yet: get it from 1st postnl arg
        _pats[0]=${_posargs[0]}

        [[ ${_posargs[0]} == -- ]] &&
            _pats[0]=${_posargs[1]}
    else
        local i idcs=() fn lines=()

        if [[ -n ${spec_idcs[0]-} ]]
        then
            # pattern args

            # extract idcs
            # - could also use:
            #   idcs=( ${spec_idcs[0]//,/ } )
            IFS=',' read -ra idcs <<< "${spec_idcs[0]}"

            # note patterns
            for i in "${idcs[@]}"
            do
                _pats+=( "${spec_args[$i]}" )
            done
        fi

        if [[ -n ${spec_idcs[1]-} ]]
        then
            # pattern-file args

            IFS=',' read -ra idcs <<< "${spec_idcs[1]}"

            for i in "${idcs[@]}"
            do
                # import patterns from file
                fn=${spec_args[$i]}

                # man grep says: the empty file contains zero patterns, and therefore
                # matches nothing.  If FILE is - , read patterns from standard input.
                # - in practice, an empty file provides no patterns, but patterns
                #   provided by other means still match as usual
                [[ $fn == '-' ]] && fn=/dev/stdin

                [[ -r "$fn" ]] &&
                    IFS='' mapfile -t lines < "$fn"

                [[ ${#lines[@]} -eq 0 ]] ||
                    _pats+=( "${lines[@]}" )
            done
        fi
    fi

    [[ ${#_pats[@]} -gt 0 ]] ||
        { err_msg 5 "no pattern"; return; }
}

# vvv old version of greps, before _parse_grepopts
#     - did not support -f
# greps() {

#     : "Smart-case wrapper function for grep

#     Usage

#         greps [opts] <pattern> [file1 or - ...]
#         greps [opts] -e <pattern1> ... [file1 or - ...]

#     The greps wrapper function passes most arguments grep, and can be used as a direct
#     replacement. However it introduces \"smart-case\" functionality, as seen e.g. in the
#     'less' pager: the pattern matching is case-insensitive for lower-case search
#     strings, but case-sensitive if the pattern includes non-escaped uppercase letters.
#     The smart-case functionality is also disabled if the options '-i' ('--ignore-case')
#     or '-j' ('--no-ignore-case') are used.
#     "

#     [[ $# -eq 0  ||  $1 == @(-h|--help) ]] &&
#         { docsh -TD; return; }

#     # return on error
#     set -o errtrace
#     #set -o functrace # ? TODO
#     trap '
#         trap-err $?
#         return
#     ' ERR

#     trap '
#         trap - err return
#     ' RETURN

#     # inherit verbosity, if any
#     local -I _v
#     [[ -n ${_v-} ]] || _v=1

#     # GNU grep arg-parsing behaviour:
#     # - grep patterns come from the first positional arg, or are given with the -e flag,
#     #   possibly multiple times, or -f gives patterns from file
#     # - if the pattern is given with -e, all positional args are expected to be files
#     # - -e 'pat' may also be written as --regexp='pat' or --regexp 'pat'


#     # Use getopts to handle greps args: -e, -f, -C, --long, etc:
#     # - getopts handles --long options smoothly using this method, but will swallow
#     #   '--' if you don't check
#     # - escapes and quotation marks, etc. are preserved in the pattern when passed as a
#     #   variable as below

#     local gopts=() pats=() _i=1
#     local flag OPTARG OPTIND=1

#     # shellcheck disable=SC2214
#     while getopts ":e:f:ijm:A:B:C:d:D:-:" flag
#     do
#         # handle long options
#         # - redefines flag and OPTARG by splitting --flag=optarg
#         _split_optarg flag

#         case $flag in
#             ( e | regexp )
#                 [[ -v OPTARG ]] || {
#                     # handle --regexp pat
#                     OPTARG=${!OPTIND}
#                     (( OPTIND++ ))
#                 }
#                 gopts+=( -e "$OPTARG" )
#                 pats+=( "$OPTARG" )
#             ;;
#             ( f | file )
#                 err_msg 2 "greps does not support the -f option"
#                 return
#             ;;
#             ( i | j | ignore-case | no-ignore-case )
#                 # disable smart-case mechanism
#                 _i=''
#                 if [[ $flag == i ]]
#                 then    gopts+=( "-$flag" )
#                 elif [[ $flag == j ]]
#                 then    gopts+=( "--no-ignore-case" )
#                 else gopts+=( "--$flag" )
#                 fi
#             ;;
#             ( m | A | B | C | d | D )
#                 # other short options that require an arg
#                 gopts+=( "-$flag" "$OPTARG" )
#             ;;
#             ( color | colour )
#                 # long options with optional arg
#                 if [[ -v OPTARG ]]
#                 then
#                     gopts+=( "--${flag}=${OPTARG}" )
#                 else
#                     gopts+=( "--$flag" )
#                 fi
#             ;;
#             ( max-count | label | after-context | before-context | context | \
#                 group-separator | binary-files | devices | directories | \
#                 exclude | exclude-from | exclude-dir | include )
#                 # other long options that require an arg
#                 [[ -v OPTARG ]] || {
#                     # handle --max-count NUM
#                     OPTARG=${!OPTIND}
#                     (( OPTIND++ ))
#                 }
#                 gopts+=( "--${flag}=${OPTARG}" )
#             ;;
#             ( \? )
#                 # other short option flags
#                 gopts+=( "-$OPTARG" )
#             ;;
#             ( ??* )
#                 # other long option flags
#                 gopts+=( "--$flag" )
#             ;;
#             ( : )
#                 err_msg 2 "-$OPTARG requires argument" # maybe just continue here?
#                 return
#             ;;
#         esac
#     done

#     # preserve '--' and clear parsed args
#     OPTIND=$(( OPTIND - 1 ))
#     [[ ${!OPTIND} == -- ]] &&
#         gopts+=( '--' )
#     shift $OPTIND

#     # pattern from 1st positional arg, if not from -e or -f
#     # - this matches how GNU grep behaves: in particular, if -f was given but empty,
#     #   grep returns 1 unless it got patterns another way

#     # with _parse_grepopts: not necessary, already done
#     [[ ${#pats[@]} -eq 0 ]] && {

#         if [[ $# -gt 0 ]]
#         then
#             pats+=( "$1" )
#         else
#             err_msg 2 "no pattern"
#             return
#         fi
#     }

#     # smart case: check for uppercase
#     # - if no upper-case letters, make the search case insensitive
#     # - *[[:upper:]]* is nice and simple, but misses regex elements like \W
#     # - Could also do [[ $pat == [[:upper:]]* || $pat == *[!\\][[:upper:]]* ]], but it
#     #   doesn't seem to make much difference: time reports both that and the regex
#     #   variant below take 0.000s for a short string match.
#     local p

#     [[ -n $_i ]] && {

#         for p in "${pats[@]}"
#         do
#             [[ $p =~ (^|[^\\])[[:upper:]] ]] && {

#                 # non-escaped uppercase found: use case sensitive search
#                 _i=''
#                 break
#             }
#         done
#     }

#     # this is safe, as the positional args are still intact
#     # - mind whether last arg is '--' ;  TODO
#     [[ -n $_i ]] &&
#         gopts+=( -i )

#     local grep_cmd
#     grep_cmd=$( builtin type -P grep ) \
#         || return

#     (
#         [[ _v -gt 0 ]] && set -x
#         "$grep_cmd" "${gopts[@]}" "$@" \
#             || exit

#     ) || return     # handle normal grep rs=1
# }
