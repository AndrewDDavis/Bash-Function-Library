# pipx env vars for --global install
# - Without --global, pipx installs by default to ~/.local/share/pipx, with symlinks
#   in ~/.local/bin and manpages at ~/.local/share/man.
# - With --global, default PIPX_GLOBAL_HOME is /opt/pipx, with symlinks in /usr/local/bin
#   and manpages at /usr/local/share/man.
export PIPX_GLOBAL_HOME=/usr/local/opt/pipx
