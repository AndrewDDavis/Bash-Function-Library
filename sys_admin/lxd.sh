# administer LXD from the container
lxcc() {
    sudo LXD_SOCKET=/root/lxd/termina_lxd.socket lxc "$@"
}
