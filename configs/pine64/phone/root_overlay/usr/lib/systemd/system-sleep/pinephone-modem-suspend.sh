#!/bin/bash                                                               

# PinePhone suspend / wakeup modem on sleep/wake
# /usr/lib/systemd/system-sleep/pinephone-modem-suspend.sh

LOGFILE=/var/log/pp-suspend.log

if grep -q 1.1 /proc/device-tree/model
then 
	DTR=358
	AP_READY=354
else
	DTR=34
	AP_READY=231
fi

if [ ! -f ${LOGFILE} ]; then
	touch ${LOGFILE}
fi

if [ "${1}" == "pre" ]; then
	NOW=`date`
	echo "$NOW Entering suspend" >> ${LOGFILE}
	echo 0 > /sys/class/modem-power/modem-power/device/powered
elif [ "${1}" == "post" ]; then
	# After wakeup
	echo 1 > /sys/class/modem-power/modem-power/device/powered
	NOW=`date`
	echo "$NOW Exiting suspend" >> ${LOGFILE}
fi
