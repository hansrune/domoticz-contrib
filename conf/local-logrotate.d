/var/log/local*.log
{
	rotate 4
	weekly
	maxsize 64M
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		invoke-rc.d rsyslog rotate > /dev/null
	endscript
}
