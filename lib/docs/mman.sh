# mman from mandoc
[[ -n $( command -v mman ) ]] && {

    true
    #mman() {
    #    mman "$@" | less
    #}
    #
    # mandoc conversion to HTML
    #mandoc -Thtml -Ostyle=style.css .../man1/foo.1.gz > foo.1.html
}
