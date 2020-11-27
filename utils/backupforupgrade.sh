#!/bin/bash
#
# Backup domoticz code before upgrades
#
PROG=$( basename $0 .sh )
DIR=$( dirname $0 ) 
HOST=$( hostname -s ) 
TIMESTR=$( date +"%Y-%m-%d" )
BACKUPDIR="backups/domoticz"
TARFILE="${BACKUPDIR}/domoticz-${HOST}-${TIMESTR}.tar.gz"

if [ ! -d ${BACKUPDIR} ]
then
	echo "$PROG: No ${BACKUPDIR} directory"
	exit 2
fi
if [ ! -f "${DIR}/backupexcludes.txt" ]
then
	echo "$PROG: No excludeslist file in ${DIR}/backupexcludes.txt" >&2
	exit 2
fi
if [ ! -x "domoticz" ]
then
	echo "$PROG: No domoticz executable in current directory" >&2
	exit 2
fi
echo "Backup to ${TARFILE}"
tar -X ${DIR}/backupexcludes.txt -czf ${TARFILE} * 

RC=$?
[ ${RC} -ne 0 ] && echo "$PROG: Failed ? Return code $RC" >&2
#
# vim:ts=4:sw=4
