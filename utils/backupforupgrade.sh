#!/bin/sh
PROG=$( basename $0 ) 
DATE=$( date +"%Y-%m-%d" )
HOST=$( hostname -s )
TAR="/tmp/domoticz-${HOST}-${DATE}.tar.gz"
tar -C /opt/domoticz --exclude="./back*" --exclude="./.n*" --exclude=./.config --exclude=./.cache -czf ${TAR} $* . && echo "$PROG: Saved in $TAR" && exit 0
RC=$?
echo "$PROG: Failed ? Return code $RC"
exit $RC
