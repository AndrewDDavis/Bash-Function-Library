
# relevant getopts behaviour (TODO: merge into notes):
# - argument '--':
#   gopts exits with status=1, sets OPT to '?', unsets OPTARG, and advances OPTIND
#   this behaviour doesn't change with silent error reporting (i.e. ':...')
# - argument '-.':
#   treated like any other valid single-letter option flag

getopts_tester() {

    [[ $# -eq 0 ]] || [[ $# -eq 1 && $1 == -h ]] && {

        : "Examine and test the getopts builtin and getopts_long function

        Example usage:

          opt_string=':ab:cd-:'
          opt_parser=( builtin getopts -- )  # or getopts_long
          getopts_tester -a -b foo -cd --flag --key=val abc
        "
        docsh -TD
        return
    }

    _print_args "$@"

    # default parser
    [[ -n ${opt_parser:-} ]] ||
        local opt_parser=( builtin getopts -- )

    printf 'opt_parser: %s\n' "$( printf '%s ' "${opt_parser[@]}" )"

    # default opt_string
    [[ -n ${opt_string:-} ]] ||
        local opt_string=':ab:cd-:'

    printf '%s\n' "opt_string: '$opt_string'"

    # print a table of values
    printf '\n%2s %2s %10s %10s %10s %10s %10s\n' \
        i j '!j' '!(j+1)' OPT OPTARG OPTIND

    local OPT OPTARG OPTIND=1 i=1 j=1 k rs

    while "${opt_parser[@]}" "$opt_string" OPT "$@"  ||  { rs=$?; ( exit $rs ); }
    do
        k=$(( j + 1 ))

        printf '%2d %2d %10s %10s %10s %10s %10s\n' \
            $i $j "${!j-(unset)}" "${!k-(unset)}" "$OPT" "${OPTARG-(unset)}" "$OPTIND"

        j=$OPTIND
        (( i++ ))
    done

    printf '\n%s\n' "return status: ${rs}"
    printf '%s\n' "shifting $(( $OPTIND - 1 ))"
    shift $(( $OPTIND - 1 ))

    _print_args "$@"


    # Getopts behaviour
    # opt-string       args   i   OPT   OPTARG OPTIND  RS Comment
    # -------------- ------ --- ------ ------- ------ --- ------------------
    # 'ab:'              -a   1      a (unset)     +1   0
    # ':ab:'             -a   1      a (unset)     +1   0
    # 'ab:'             -aa   1      a (unset)     +0   0 Sub-OPTIND tracked internally
    # 'ab:'             -aa   2      a (unset)     +1   0
    # 'ab:'             -a1   1      a (unset)     +0   0
    # 'ab:'             -a1   2      ? (unset)     +1   0 msg: illegal option -- 1
    # ':ab:'            -a1   2      ?      1      +1   0
    #
    # 'ab:'             -b1   1      b      1      +1   0
    # 'ab:'            -b 1   1      b      1      +2   0
    # 'ab:'              -b   1      ? (unset)     +1   0 msg: option requires an argument -- b
    # ':ab:'             -b   1      :      b      +1   0
    #
    # 'ab:'      -ab1 -- -c   1      a (unset)     +0   0
    # 'ab:'      -ab1 -- -c   2      b      1      +1   0 '--' terminates loop, increments OPTIND
    # ':ab:'     -ab1 -- -c   2      b      1      +1   0 same with silent error reporting
    #
    # 'ab:'              -d   1      ? (unset)     +1   0 msg: illegal option -- d
    # ':ab:'             -d   1      ?      d      +1   0
    #
    # ^^^ getopts_long consistent up to here
    #
    # 'a'              -a--   1      a (unset)     +0   0
    # 'a'              -a--   2      ? (unset)     +0   0 msg: illegal option -- -
    # 'a'              -a--   3      ? (unset)     +1   0 msg: illegal option -- -
    # ':a'             -a--   2      ?      -      +0   0
    # ':a'             -a--   3      ?      -      +1   0
    # 'a-:'            -a--   2      -      -      +1   0
    # ':a-:'           -a--   2      -      -      +1   0
    #
    # 'a b:'           -' '   1  (sp.) (unset)     +1   0 space is a valid flag, if in opt-string
    #
    # 'ab:-: foo'     --foo   1      -    foo      +1   0 allows for long-opt handling

    # Getopts_long only vvv
    # 'a foo'         --foo   1    foo (unset)     +1   0
    # 'a foo:'    --foo=bar   1    foo    bar      +1   0
    # 'a foo:'    --foo bar   1    foo    bar      +2   0
    # 'a foo:'        --foo   1      ? (unset)     +1   0 msg: option requires an argument -- foo
    # ':a foo:'       --foo   1      :    foo      +1   0
    # 'a foo:'        --bar   1      ? (unset)     +1   0 msg: illegal option -- bar
    # ':a foo:'       --bar   1      ? foobar      +1   0
    # 'a b foo'       --foo   1    foo (unset)     +1   0
}


# TODO:
# - address difference btw getopts and getopts_long for -a-- arg
# - address difference btw getopts and getopts_long for -' ' arg with space in opt-string
# - old note: currently testing with the grep-files function, switch to unit test

_args_unit_test() {

    # - unit test for arg_lumper and arg_def, sets variables based on arguments provided to
    #   function

    echo '...'

    _test_al() {
        # expected strings
        local x_opt=$1 x_lump=$2
        shift 2

        # number of runs
        local r n=1
        if [[ $1 == -n[0-9]* ]]
        then
            n=${1#-n}
            shift
        fi

        # test
        local tst_str="Testing Args (n=$n): ${*@Q}"

        local opt lump

        for r in $( seq $n )
        do
            _arg_lumper opt lump "$@"
            [[ -z ${lump:-} ]] && shift
        done

        # report
        local rep_str=()

        # we don't distinguish unset vs empty
        [[ -v opt ]] || opt=''
        [[ -v lump ]] || lump=''

        if ! [[ $x_opt == ${opt@Q} ]]
        then
            rep_str+=( "    ${_cfg_r}Expected:${_cfg_d} ${x_opt}" )
            rep_str+=( "         ${_cfg_r}Got:${_cfg_d} ${opt@Q}" )
        fi

        if ! [[ $x_lump == ${lump@Q} ]]
        then
            rep_str+=( "    ${_cfg_r}Expected:${_cfg_d} ${x_lump}" )
            rep_str+=( "         ${_cfg_r}Got:${_cfg_d} ${lump@Q}" )
        fi

        if [[ ${#rep_str[@]} -eq 0 ]]
        then
            printf '%s\n' "${tst_str}" "    ${_cfg_g}Pass:${_cfg_d} ${opt@A} ${lump@A}"
            return 0
        else
            printf '%s\n' "$tst_str" "${rep_str[@]}"
            return 2
        fi
    }

    # flag variables
    _test_al "'a'" "''" -a
    _test_al "'b'" "'cd'" -n2 -abcd
    _test_al "'foo'" "''" --foo
    _test_al "'-'" "''" -
    _test_al "'--'" "''" -n2 -a -- -b
    _test_al "'key'" "'val'" -n2 -a --key=val

    unset -f _test_al
}

# Unit testing shell scripts
# TODO: continue reading and making notes from link below.
# - Notes from: https://www.leadingagile.com/2018/10/unit-test-shell-scripts-part-one
# - also see the [Bash Automated Testing System](https://github.com/bats-core/bats-core)
#
# Principles:
# - only test what is _in scope_ for a script; e.g. functionality of external commands
#   is not something to test, but the parsing of the output of those commands is.
# - where necessary, create _mock_ commands for external commands, e.g. a mock `df`
#   command that simply echos the expected output of df, which is aliased to df while
#   the unit test runs.
# - the output of the mock commands is piped around and processed in the same way as the
#   real output of the command would be.
