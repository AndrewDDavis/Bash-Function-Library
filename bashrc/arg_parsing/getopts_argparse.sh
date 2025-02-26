# Functions to support argument parsing with getopts or in a while loop

_arg_lumper() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Parse a positional argument by splitting it, or just cycle the lump

        Usage: ${FUNCNAME[0]} opt lump \"\${1:-}\"

        ${FUNCNAME[0]} sets the opt and lump variables in the following ways:

        | Type        | E.g.      |  opt | lump |
        | ----------- | --------- | ---- | ---- |
        | Short Flag  |        -a |    a |      |
        | Long Flag   |     --foo |  foo |      |
        | Lumped Flag |     -abcd |    a |  bcd |
        | Key & value | --key=val |  key |  val |
        | Special     |         - |    - |      |
        | Special     |        -- |   -- |      |

        Moreover, if \`lump\` is set to a non-empty value when ${FUNCNAME[0]} is called,
        \`opt\` will be set to the first character of \`lump\` and \`lump\` will be set
        to the remaining characters, without using the positional argument provided.

        After running ${FUNCNAME[0]} to parse an argument, a case statement should
        follow to take appropriate actions depending on the value of opt. When opt
        indicates that an argument is due, _arg_def should be used to get the value,
        either from the next arg or the lump.

        If _arg_def uses the lump, the lump variable is unset.


        - maybe lump should be set to '-', to indicate that happened? otherwise, I don't
        know how to distinguish btw the two cases, maybe return value

        is it enough to do that and then have this at the end of the loop:

            [[ $lump == '-' ]] && unset lump
            [[ -z ${lump:-} ]] && shift
        done

        ^^^ Do we need "optarg" as well as lump? The lump case is actually different
            from key=val...
            Or I could set lump to '-' as a "signal", either here or in _arg_def




        ${FUNCNAME[0]} returns code 0 (true) if there is a non-empty lump, or if the
        first positional arg starts with '-'. Otherwise, it returns 1 (false).


        old text, not sure if this still applies:

        Thus, the first positional argument should only be discarded
        (e.g. using \`shift\`) if \`lump\` is empty or unset, and \`lump\` should be emptied
        or unset if it is used as an argument to an option. This may be accomplished
        using the \`_arg_def\` function, with a check on its return status.

        - Previously, the while loop relied on the first positional arg being set and starting
        with '-', so it needed to be kept (not shifted) until it was fully used (i.e.
        until the lump is empty).
        - Now, the lumper function is called at the top of the loop, so the arg could be
          shifted right away.


        Example

          # Parse command-line arguments
          local opt lump

          while ${FUNCNAME[0]} opt lump \"\$@\"
          do
              case \$opt in
                  ( -- )
                      # end of options (e.g. for a stand-alone function)
                      #shift; break

                      # or pass it on (e.g. for a wrapper function)
                      #opts+=( \$opt )
                  ;;
                  ( f | foo )
                      # short or long flag option
                      # can be used as '-f', '-fghi', or '--foo'
                      foo='True'
                  ;;
                  ( j | jar )
                      # short or long option with argument
                      # can be used as '-j arg', '-jarg', '--jar arg', or '--jar=arg'
                      _arg_def baz || {
                          [[ \$? -eq 1 ]] && shift || return
                      }
                  ;;
                  ( key )
                      # manual long option with arg?
                      # maybe...
                      val=\$lump; unset lump ;;
                  ...
                  ( a )  _ap_addto_arrvar _andpat \"\${2:-}\" || {
                              [[ \$? -eq 1 ]] && shift || return
                          } ;;
                  ( * )
                      # unknown arg, which is normal for a wrapper function
                      #break
                      # ^^^ preserves option arg
                      # consider throwing error instead
                  ;;
              esac

              [[ -z \${lump:-} ]] && shift
          done
        "
        return 0
    }

    [[ $# -lt 3 ]] && {
        err_msg 2 "Usage: ${FUNCNAME[0]} opt lump \"\${1:-}\""
        return 2
    }

    local -n optn=$1 lumpn=$2
    shift 2

    if [[ -n ${lumpn:-} ]]
    then
        # could also test for lumpn being set with [[ -v lumpn ]] (can be empty)

        # next from lump
        optn=${lumpn:0:1}
        lumpn=${lumpn:1}

        # if lumpn is empty, set it to - as a signal?

    elif [[ ${1:-} == -* ]]
    then
        # use positional arg
        case $1 in
            ( - | -- )
                optn=$1
            ;;
            ( --* )
                # long option like --foo or --key=val
                optn=${1:2}

                if [[ $optn == *=* ]]
                then
                    lumpn=${optn#*=}
                    optn=${optn%%=*}
                fi
            ;;
            ( -* )
                # single-letter option like -a, or lump of them like -abcd
                optn=${1:1:1}

                if [[ ${#1} -gt 2 ]]
                then
                    lumpn=${1:2}
                fi
            ;;
        esac

    else
        return 1
    fi
}


_arg_def() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Define named var from \`lump\` or next positional arg.

        Usage: ${FUNCNAME[0]} <var-name> lump \"\$@\"

        Returns 0 if the value is taken from \`lump\`, or 1 if taken from next arg.

        Example

          # ... as in _arg_lumper

          case \$opt in
              ( f )  ${FUNCNAME[0]} foo lump \"\$@\" || shift

          # ...
        "
        return 0
    }

    local -n varn=$1 lumpn=$2     # name-refs
    shift 2

    # get required arg from lump or next arg
    if [[ -n ${lumpn:-} ]]
    then
        varn=$lumpn
        unset lumpn
        return 0

    elif [[ -n ${1:-} ]]
    then
        varn=$1
        return 1

    else
        err_msg 3 "unable to set '${!varn}' from '${!lumpn}' or '\$1'"
        return 3
    fi
}


_arg_addto_arrvar() {
    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Used in arg-parsing, like _arg_def, but add required arg to array.

        Usage: _ap_add_arrvar <var-name> lump \"\${1:-}\" || shift

        Like _arg_def, returns 0 if the value is taken from \`lump\`, or 1 if taken from
        next arg.
        "
        return 0
    }

    local -n varn=$1 lumpn=$2     # name-refs
    shift 2

    # get required arg from lump or next arg
    if [[ -n ${lumpn:-} ]]
    then
        varn+=( "$lumpn" )
        unset lumpn
        return 0

    elif [[ -n ${1:-} ]]
    then
        varn+=( "$1" )
        return 1

    else
        err_msg 3 "unable to add to '${!varn}' using '${!lumpn}' or '\$1'"
        return 3
    fi
}





_def_opt_lump() {

    [[ $# -eq 0 ]] && {

        docsh -TD "Define variables 'opt' and 'lump' when parsing arguments

        Usage: ${FUNCNAME[0]} \"\$1\"

        - For an argument like \`-a\`, sets \`opt=a\` and \`lump\` remains unset.
        - For an argument like \`--foo\`, sets \`opt=foo\` and \`lump\` remains unset.
        - For an argument like \`-abcd\`, sets \`opt=a\` and \`lump=bcd\`.
        - For \`--key=val\`, sets \`opt=key\` and \`lump=val\`.
        - If the whole argument is \`-\`, sets \`opt=-\`.
        - If the whole argument is \`--\`, returns 1 without setting \`opt\` or \`lump\`.

        Example

          local opt lump

          while [[ \${1:-} == -* ]]
          do
              ${FUNCNAME[0]} \"\$1\" || { shift; break; }

              while [[ -n \${opt:-} ]]
              do
                  case \$opt in
                      ( f )  foo=1 ;;
                      ...
                      ( a )  _ap_add_arrvar _andpat \"\${2:-}\" || {
                                 [[ \$? -eq 1 ]] && shift || return
                             } ;;
                      ( * )  break 2  # preserves option arg; consider throwing error ;;
                  esac

                  # next from lump, if any
                  opt=\${lump:+\${lump:0:1}}
                  lump=\${lump:+\${lump:1}}
              done

              shift
              unset opt lump
          done
        "
        return 0
    }

    echo "try _arg_lumper instead"
    return

    case $1 in
        ( -- )
            # end of options
            return 1
        ;;
        ( --* )
            # long option like --foo or --key=val
            opt=${1:2}

            if [[ $opt == *=* ]]
            then
                lump=${opt#*=}
                opt=${opt%%=*}
            fi
        ;;
        ( -* )
            # single-letter option like -a, or lump of them like -abcd
            opt=${1:1:1}
            [[ ${#1} -gt 2 ]] && lump=${1:2}

            # handle -
            [[ -z $opt ]] && opt="-"
        ;;
    esac
}

_split_opt_lump() {

    [[ $# -eq 0 ]] && {

        docsh -TD "Split a positional argument into 'opt' and 'lump' parts

        Usage:  IFS=\$'\\n' read -rd '' opt lump < <( ${FUNCNAME[0]} \"\$1\" )

        - For an argument like \`-a\`, outputs only \`a\`.
        - For an argument like \`--foo\`, outputs only \`foo\`.
        - For an argument like \`-abcd\`, outputs \`a\` and \`bcd\` on separate lines.
        - For \`--key=val\`, outputs \`key \\n val\`.
        - If the whole argument is \`-\`, outputs only \`-\`.
        - If the whole argument is \`--\`, returns 1 with no output.

        Example

          local opt lump

          while [[ \${1:-} == -* ]]
          do
              IFS=\$'\\n' read -rd '' opt lump < <( ${FUNCNAME[0]} \"\$1\" )

              while [[ -n \${opt:-} ]]
              do
                  case \$opt in
                      ( f )  foo=1 ;;
                      ...
                      ( a )  _ap_add_arrvar _andpat \"\${2:-}\" || {
                                 [[ \$? -eq 1 ]] && shift || return
                             } ;;
                      ( * )  break 2  # preserves option arg; consider throwing error ;;
                  esac

                  # next from lump, if any
                  opt=\${lump:+\${lump:0:1}}
                  lump=\${lump:+\${lump:1}}
              done

              shift
              unset opt lump
          done
        "
        return 0
    }

    echo "try _arg_lumper instead"
    return


    local opt lump

    case $1 in
        ( -- )
            # end of options
            return 1
        ;;
        ( --* )
            # long option like --foo or --key=val
            opt=${1:2}

            if [[ $opt == *=* ]]
            then
                lump=${opt#*=}
                opt=${opt%%=*}
            fi
        ;;
        ( -* )
            # single-letter option like -a, or lump of them like -abcd
            opt=${1:1:1}
            [[ ${#1} -gt 2 ]] && lump=${1:2}

            # handle -
            [[ -z $opt ]] && opt="-"
        ;;
    esac

    printf '%s\n' "$opt" "${lump:-}"
}

_ap_set_var() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "used in arg-parsing: get required arg from lumped string or next arg.

        Usage: _ap_set_var <var-name> \"\${1:-}\" || shift

        Hint: check _arg_def instead

        "
        return 0
    }

    echo "try _arg_def instead"
    return

    local -n var=$1     # name-ref to the variable to set

    # get required arg from lump or next arg
    if [[ -n ${lump:-} ]]
    then
        var=$lump
        unset lump
        return 0
    elif [[ -n $2 ]]
    then
        var=$2
        return 1
    else
        err_msg 3 "missing required arg to set '$1' for '$opt'"
        return 3
    fi
}

_ap_add_arrvar() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "used in arg-parsing: like _ap_set_var, but add required arg to array.

        Usage: _ap_add_arrvar <var-name> "\${1:-}" || shift

        Hint: use _arg_addto_arrvar instead
        "
        return 0
    }

    echo "use _arg_addto_arrvar instead"
    return 3

    local -n var=$1     # name-ref to the variable to set

    # get required arg from lump or next arg
    if [[ -n ${lump:-} ]]
    then
        var+=( "$lump" )
        unset lump
        return 0
    elif [[ -n $2 ]]
    then
        var+=( "$2" )
        return 1
    else
        err_msg 3 "missing required arg to add to '$1' for '$opt'"
        return 3
    fi
}

_ap_pop_last() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "assign last positional arg to variable

        I couldn't get this function to work without requiring complicated syntax on the
        receiving side, which defeats the purpose.

        Instead, just use this code in your function:

          var=\${@:(-1)}
          set -- \"\${@:1:\$#-1}\"


        Usage (above is recommended instead)

          _ap_pop_last <var-name> <arr-name>
          set -- \"\${arr-name[@]}\"

        Assigns last post'l arg to var-name, then assigns remaining post'l args to
        arr-name. Assign the post'l args to arr-name, as above, to remove the last arg,
        if desired.
        "
        return 0
    }

    local -n var=$1     # name-ref to the variable that will be assigned to
    local -na arr=$2    # name-ref to the array that will be assigned to

    var=${@:(-1)}
    arr=${@:1:$#-1}

    # originally tried to find a form of printf or e.g. ${arr@Q}, couldn't find one
    #printf '%q\n' "$@"
}
