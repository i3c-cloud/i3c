#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

service dbus start

#mintlocale

if [ -e /i3c/data/run-defaults.sh ]; then
	. /i3c/data/run-defaults.sh
fi
