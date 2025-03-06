git-show-toplevel() {

    : "print the top-level directory of the current git repo"
    # no args expected
    # convert HOME to ~
    git rev-parse --show-toplevel "$@" | sed "s:^${HOME}:~:"
}

git-fzadd() {

    : "git alias to select files to add"

    # maybe this should be a git alias in the git config, like:
    # fza = "!git ls-files -m -o --exclude-standard | fzf -m --print0 --preview "git diff {1}" | xargs -0 git add"

    # git ls-files:
    # -m and -o show modified and untracked (other) files

    # fzf:
    # -m allows multi-select with Tab

    git ls-files -mo --exclude-standard |
        fzf -m --print0 --preview 'git diff {1}' |
        xargs -0 git add
}


# The Git aliases below are now defined in git config, e.g. `git br`.

#alias gits='git status'
#alias gitf='git fetch --all'
#alias gitdw='git diff --word-diff'  # use -S while pager is running to wrap lines
#alias gitdp='GIT_PAGER="" git diff -U0 --word-diff'
#alias gita='git add'
#alias gitcm='git commit -m'
#function gitacp {
#    [[ $# -eq 2 ]] || { echo "2 args expected"; return; }
#    git add "$1"
#    git commit -m "$2"
#    git push
#}
