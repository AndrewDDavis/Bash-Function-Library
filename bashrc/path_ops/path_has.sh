path_has () {

    # check whether pp arg is already in PATH
    local pp=$1

    # the specificity of this pattern is needed for paths like '/bin'.
    case "$PATH" in
        "$pp" | "$pp:"* | *":$pp" | *":$pp:"* )
            return 0
            ;;
        * )
            return 1
            ;;
    esac
}
