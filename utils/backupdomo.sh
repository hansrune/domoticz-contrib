#!/bin/bash
#
# Backup and email domoticz database
#
PROG=$( basename $0 )
MAILTO=${MAILTO:-"domo@hansrune.net"}
DOMOPID=$( pgrep -x domoticz )
[ -n "$DOMOPID" ] && PORT=$( ps -p "$DOMOPID" -o args --no-header |sed -ne 's/.*-www \([0-9][0-9]*\).*/\1/p' )
PORT=${PORT:-"8080"}
HOST=$( hostname -s ) 
TIMESTR=$(  date '+%F %T' |tr  ': -' '.\-.' )
BASENAME="domoticz-${HOST}-${TIMESTR}"
BODY="Domoticz backup from $HOST at ${TIMESTR}"
#sudo service domoticz.sh stop 
cd /tmp
if wget -q -O "/tmp/${BASENAME}.db" "http://127.0.0.1:$PORT/backupdatabase.php" 
then
	gzip -9 "/tmp/${BASENAME}.db"
	mail -s "Domoticz backup from $HOST at ${TIMESTR}" -A "/tmp/${BASENAME}.db.gz" --content-type=application/zip ${MAILTO} <<< "${BODY}"
else
	mail -s "Domoticz backup from $HOST failed at ${TIMESTR}" ${MAILTO} <<< "${BODY}"
fi
rm -f "/tmp/${BASENAME}.db.gz" 
#sudo service domoticz.sh start
