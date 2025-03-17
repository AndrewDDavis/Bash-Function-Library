# root priv required to test socket existence
if sudo -n true
then
    if sudo /bin/test -e /root/lxd/termina_lxd.socket
    then
        lxcc() {

            : "Administer LXD from a guest container"

            sudo LXD_SOCKET=/root/lxd/termina_lxd.socket lxc "$@"
        }
    fi
fi
