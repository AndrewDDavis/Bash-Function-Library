sh_log() {

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "print messages from functions.

        Usage example

        # set verbosity level to info
        _verb=6

        ${FUNCNAME[0]} -v6 "something happened"
        "
        return 0
    }

    # TODO
    # - allow logfile setting to get output at certain verbosity
    # - and allow stdout verbosity level, so some messages are printed
    echo not implemented
    return

    # __VERBOSE=6

    # declare -A LOG_LEVELS
    # # https://en.wikipedia.org/wiki/Syslog#Severity_level
    # LOG_LEVELS=( [0]="emerg"
    #              [1]="alert"
    #              [2]="crit"
    #              [3]="err"
    #              [4]="warning"
    #              [5]="notice"
    #              [6]="info"
    #              [7]="debug" )
    # function .log () {
    #   local LEVEL=${1}
    #   shift
    #   if [ ${__VERBOSE} -ge ${LEVEL} ]; then
    #     echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
    #   fi
    # }
}
