# Sudo
# aliases: allow alias expansion in sudo command
alias sudoa="sudo "

sudop() {
    # Keep user's PATH for sudo command

    # opt 1: sudo $(command -v $1)

    # opt 2: pass user's PATH to sudo
    sudo PATH="$PATH" "$@"
}

