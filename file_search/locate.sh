#!/bin/sh

if [ "$( uname -s )" = Darwin ]
then
    # BSD locate on macOS
    # - NB, updatedb on macOS is locate.updatedb
    export LOCATE_CONFIG="$HOME/.config/locate/locate.rc"
    export LOCATE_PATH="$HOME/.cache/locate/locate.database"
fi
