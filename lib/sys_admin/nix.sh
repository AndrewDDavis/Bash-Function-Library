# Run Nix with increased verbosity by default
[[ -n $( command -v nix ) ]] &&
    alias nix="nix -v"
