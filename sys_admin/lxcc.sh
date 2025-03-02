lxcc() {

    : "administer LXD from the container"

    sudo LXD_SOCKET=/root/lxd/termina_lxd.socket lxc "$@"
}
