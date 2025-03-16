rename-sstr() {

    [[ $# -lt 3  ||  $1 == @(-h|--help) ]] && {

        : "Safely rename files using substring replacement

        Usage: rename-sstr [-x] <substr> <replacement> <filename> [fn2 fn3 ...]

        - Operates in current dir.
        - Only shows operation by default, use -x to execute rename.

        Alternatives

        - For more robust treatment of regular expressions, use the perl function
          'rename' from the repos.

        - For simple string replacement, adding, and subtracting, on a single file,
          just use the shell's brace expansion instead, e.g.:

          touch file_abc.ext
          mv file_{abc,def}.ext
          mv file_def{,ghi}.ext
          ls -l file_defghi.ext

        TODO:
        - add a global option (-g) to replace more than one instance of the string
        - Consider adding a -E option to use 's///' syntax with sed.
        - Also add -q for quiet (no echo of files)
        "
        docsh -TD
        return
    }

    local _x srch repl

    [[ $1 == -x ]] &&
        { _x=1; shift; }

    srch=$1
    repl=$2
    shift 2

    [[ $# -eq 0 ]] &&
        return 1

    local fn newfn

    for fn in "$@"
    do
        [[ -e $fn ]] ||
            { err_msg 3 "file not found: $fn" "aborting..."; return; }

        newfn=${fn/${srch}/${repl}}

        if [[ -n ${_x-} ]]
        then
            command mv -vi "$fn" "$newfn" ||
                break
        else
            # use bold and dim to emphasize replaced text
            # - refer to the csi_strvars function:
            #   [[ -z ${_cbo-} ]] && csi_strvars -d
            # - not using _cbo, as it's got prompt \[...\] chars
            local _bld _dim _rsb _rsd _rst
            _bld=$'\e[1m'
            _dim=$'\e[2m'
            _rsb=$'\e[22m'
            _rsd=$'\e[22m'
            _rst=$'\e[0m'

            printf '   %s\n-> %s\n\n' \
                "${fn/$srch/${_dim}$srch${_rsd}}" \
                "${newfn/$repl/${_bld}$repl${_rsb}}"
        fi
    done
}
