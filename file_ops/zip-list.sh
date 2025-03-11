alias unzip-list="zip-list"

zip-list() {
    : "List zip archive contents"
    unzip -l "$@"
}
