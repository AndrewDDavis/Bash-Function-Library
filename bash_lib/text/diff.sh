# diff

### Colourized output
if  (( ${TERM_NCLRS:-2} >= 8 )) \
        && diff --color /dev/null /dev/null &>/dev/null
then
    alias diff="diff --color=auto"
fi

# completion: same as diff
# found by doing diff -[Tab] in a terminal, then typing Ctrl-\ and running 'complete -p diff'
complete -F _comp_complete_longopt \
    diff-u \
    diff-y \
    diff-w \
    diff-yw

diff-u() {

    : """Show a patch diff with colour in a pager

    Usage: diff-u [diff-opts] file1 file2

    diff options in effect:

     -u : patch (3 unified context lines around changes)
     -s : report identical files
    """

    diff -us --color=always "$@" | less -FR
}

# git diff
alias diff-g="git diff --minimal --no-index"

# just report changed
alias diff-qs="diff -qs"


### Word diff

# git word-diff
# - NB, plain mode uses color too
# - NB, anything the in word-diff-regex is considered whitespace, and ignored(!) for
#   the purposes of finding differences. So, probably better to stick with the default,
#   rather than e.g.: --word-diff-regex='[^[:punct:][:space:]]+'
alias diff-gw='git diff --no-index --minimal --word-diff'

# dwdiff
# - dwdiff is better, allows punct as word boundary; still shares the annoyance of
#   sometimes introducing a space into the output
[[ -n $( command -v dwdiff ) ]] \
    && alias diff-dw='dwdiff --color'

# diffr
# - processes the output of 'diff -u' to highlight words; this is pretty good
diff-hldiffr () {
    diff -u "$@" \
        | diffr
}

# wdiff
# - NB, this is old software, doesn't produce colour by default
#   from an online hack to make wdiff output in colour:
#   ```sh
#   #!/bin/bash
#   esc=$(printf '\033[')
#   wdiff -n -w "${esc}1;31m" -x "${esc}m" -y "${esc}1;34m" -z "${esc}m" "$@" | fgrep -C2 "$esc"
#   exec cmp -s "$@"
#   ```

# diff-highlight
# - this package, which ships with git, also tries to postprocess diff output to
#   highlight words, but isn't very good; see /usr/share/doc/git/contrib/diff-highlight/README
#diff-hl () {
#
#    git diff --no-index --color "$@" |
#        perl /usr/share/doc/git/contrib/diff-highlight/diff-highlight
#}


### Side-by-side diff

# side-by-side diff with -y
# -t : tabs -> spaces
alias diff-sbs="diff -yts"

diff-sbsw() {
    # side-by-side word diff
    # uses overall width of 120 columns
    diff -yts --color=always -W 120 <( fold -s -w46 "$1" ) <( fold -s -w46 "$2" )
}


### Merge files

# merge with ifdef statements marking differences
# - can leave the #if and #endif statements, and later do
#   grep -v '^#if' merged.xml | grep -v '^#endif' > clean.xml
alias diff-mrg-ifdef="diff -D NEWSTUFF"

diff-mrg-quick () {
    # quick merge using diff -u
    # - this creates a fully unified file, with patch-style diff areas
    # - probably better would be to edit the merge file and use `patch`, as intended

    [[ -e dmq.merge ]] && return 1

    diff -u 999999 "$1" "$2" > dmq.merge
    $EDITOR dmq.merge        # edit as desired

    sed -i'' 's/^.//' dmq.merge  # remove leading chars
}

diff-mrg-patch () {
    # patch after using diff -u
    # - probably better would be to edit the merge file and use `patch`, as intended

    [[ -e dmp.merge ]] && return 1

    diff -u3  "$1" "$2" > dmp.merge
    $EDITOR dmp.merge        # edit as desired

    #sed -i'' 's/^.//' dmp.merge  # remove leading chars
    echo patch...
}

# sdiff: side-by-side diff
# - see usage at https://www.jpeek.com/articles/linuxmag/2007-05
# - hit enter for help
# - would be nice to make this a function, have the column widths only as large as needed
#sdiff -o merged.file left.file right.file
alias diff-mrg-sdiff="sdiff -w $(tput cols) -lt --tabsize=4 -o"


## Directory diff

# ... TODO

# regular Gnu diff:
#  -N causes missing files to be considered empty
# diff -qr dir1/ dir2/
# diff -qr dir1/ dir2/ | grep ' differ'
# diff -qrN dir1/ dir2/
# diff -qrN --no-dereference --no-ignore-file-name-case dir1/ dir2/ > dirdiff_1.txt

# git diff:
# - nice colour
# git diff --no-index dir1/ dir2/

# meld:
# - can dig down to file diff mode when you see what differs
# meld dir1/ dir2/

# rsync
# - flexible syntax
# - use -n for dry-run, -c for checksums
# rsync -n -rlcv --delete /dir{1,2}/ > dirdiff_2.txt

# maybe check out [diffoscope](https://diffoscope.org/)

