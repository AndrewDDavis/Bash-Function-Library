# Flexget config

[[ -d /usr/local/flexget ]] && alias flexact='source /usr/local/flexget/bin/activate'

#flexconfile="/var/lib/flexget-daemon/.flexget/config.yml"
#flexlogfile="/var/log/flexget-daemon/flexget-daemon.log"
#[[ -e "$flexconfile" ]] \
#  && { alias flexconf="md5sum $flexconfile > /tmp/flexconf.md5sum;
#       nano $flexconfile \
#         && { if md5sum -c /tmp/flexconf.md5sum --status --strict; then
#                echo 'No changes.';
#              else
#                echo 'Checking config...';
#                flexget -c $flexconfile --logfile "/var/log/flexget-daemon/flexget-daemon.log" check \
#                  && echo -e 'Check passed.  To load the new config to a running daemon, run:\n  sudo initctl reload flexget-daemon' \
#                  || echo 'Check failed.';
#              fi;
#             }"
#        alias flexget="flexget -c $flexconfile -l $flexlogfile"
#      }
#unset flexconfile flexlogfile
