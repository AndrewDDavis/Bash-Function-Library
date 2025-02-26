# Move, copy
# - note alias rm="rm -I" is not valid in BSD rm
alias cp="cp -i"        # prompt before overwrite
alias mv="mv -i"        # prompt before overwrite

# mkbak -> cp-bak (below)
alias mkbak="cp-bak"

cp-bak() (

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {

        docsh -TD "Create simple file backup copies

        Usage : ${FUNCNAME[0]} [opts] [--] [cp-opts] <filename> ...

        Options (unrecognized options are passed on to cp):

          -d <dir>
          : create copy in dir, rather than next to input file

          -e <.foo>
          : use extension .foo (or e.g. '~') instead of .bak

          -o
          : use .old extension instead of .bak

          -O
          : use .orig extension instead of .bak

          -q
          : omit verbose copy output

          -v
          : show result of copy using 'ls -l' (-vv to also show verbose copy op)

        ${FUNCNAME[0]} makes a copy of each filename, creating a unique file name by
        appending .bak and possibly an integer, as necessary. The copy is performed
        using 'cp -pi' by default, to preserve permissons and modification times, and
        not clobber existing files.

        A warning is printed if the file copy differs from the original in permissions
        or ownership. Since cp dereferences symlinks by default, this check does too.

        This function is intended for simple file backups, e.g. when editing config
        files, to allow quick reversion of changes. For a full incremental backup
        solution, use e.g. borg-go or tar.
        "
        return 0
    }

    # clean up on return
    trap 'unset -f _show_stats _chk_stats
          trap - RETURN ERR' RETURN

    # return on errors
    trap 'trap-err $?
          return' ERR

    # extend traps to sub-functions
    shopt -os errtrace    # functions inherit the ERR trap
    #shopt -os functrace   # functions inherit RETURN and DEBUG traps

    # args
    local odir bk_ext=.bak vrb=1 cp_opts=( -pi )

    local OPT OPTARG OPTIND=1

    while getopts ":d:e:oOqv" OPT
    do
        case $OPT in
            ( d ) odir=${OPTARG%/} ;;
            ( e ) bk_ext=$OPTARG ;;
            ( o ) bk_ext=.old ;;
            ( O ) bk_ext=.orig ;;
            ( q ) vrb=$(( vrb - 1 )) ;;
            ( v ) vrb=$(( vrb + 1 )) ;;
            ( \? ) cp_opts+=( -"$OPTARG" ) ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    # verbose copy operation
    [[ $vrb -eq 1  ||  $vrb -gt 2 ]] &&
        cp_opts+=( -v )

    _show_stats() {
        # print mode (octal), user and group IDs in expected format
        # args: filename
        stat -L --format='%04a %u:%g' "$1"
    }

    _chk_stats() {
        # check for consistent metadata

        # keep local as a separate cmd, to retain return status
        local l _msg f1_stats f2_stats

        # don't use proc subst, so we retain the return status
        #read -r f1_md f1_ug < <( _show_stats "$1" )
        #read -r f2_md f2_ug < <( _show_stats "$2" )
        f1_stats=( $( _show_stats "$1" ) )
        f2_stats=( $( _show_stats "$2" ) )

        # minimum filename string length
        l=8
        [[ ${#1} -gt $l ]] && l=${#1}
        [[ ${#2} -gt $l ]] && l=${#2}

        # mode
        if [[ ${f1_stats[0]} != ${f2_stats[0]} ]]
        then
            # show a warning message for differences
            printf -v _msg "%-${l}s  %6s\n" \
                "filename" "mode" \
                "$( str_rep - $l )" "$( str_rep - 6 )" \
                "$1" "${f1_stats[0]}" \
                "$2" "${f2_stats[0]}"

            printf '\n'
            err_msg w "$_msg"
        fi

        # ownership
        if [[ ${f1_stats[1]} != ${f2_stats[1]} ]]
        then
            printf -v _msg "%-${l}s  %12s\n" \
                "filename" "owner:group" \
                "$( str_rep - $l )" "$( str_rep - 12 )" \
                "$1" "${f1_stats[1]}" \
                "$2" "${f2_stats[1]}"

            printf '\n'
            err_msg w "$_msg"
        fi
    }


    for fn in "$@"
    do
        [[ -d $fn ]] && {
            echo >&2 "Warning: directories not supported (try tar); skipping ${fn}"
            continue
        }

        # split fn
        local fbn=$( basename "$fn" )
        local fdn=$( dirname "$fn" )

        # add ./ for relative paths, for consistency of later reporting
        [[ $fdn == '.'  &&  ${fn:0:2} != './' ]] &&
            fn="./$fn"

        # if file already has .bak, make abc.bak2 instead of abc.bak.bak
        [[ $fn == *${bk_ext} ]] &&
            bk_ext=''

        # output to same dir unless otherwise specified
        [[ -z ${odir:-} ]] &&
            odir=$fdn

        # propose new filename
        bk_fn=${odir}/${fbn}${bk_ext}

        # add integer as necessary
        i=1
        while [[ -e ${bk_fn} ]]
        do
            let 'i += 1'
            bk_fn=${odir}/${fbn}${bk_ext}${i}

            (( i == 100 )) && {
                err_msg 2 "found 99 backup files for $fn, aborting."
                return 2
            }
        done

        # perform copy
        command cp "${cp_opts[@]}" "$fn" "$bk_fn"

        # check metadata consistency of copy
        _chk_stats "$fn" "$bk_fn"

        if [[ $vrb -gt 1 ]]
        then
            printf '\n%s\n' "Result:"
            ls -l "$fn" "$bk_fn"
            printf '\n'
        else
            true
        fi
    done
)
