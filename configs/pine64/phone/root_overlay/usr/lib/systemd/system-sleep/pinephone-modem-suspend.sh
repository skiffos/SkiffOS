#!/bin/bash                                                               
# From: https://www.ironrobin.net/pureos/git/clover/pinephone/raw/branch/master/usr/lib/systemd/system-sleep/pinephone-modem-suspend.sh
# PinePhone suspend / wakeup modem
# /usr/lib/systemd/system-sleep/pinephone-modem-suspend.sh

# DTR is:     
# - PL6/GPIO358 on BH (1.1)
# - PB2/GPIO34 on CE (1.2)

# AP_READY is:                  
# - PL2/GPIO354 on mozzwalds BH (1.1), not connected on others
# - PH7/GPIO231 on CE (1.2)

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
	# Before Suspend
	NOW=`date`
	echo "$NOW Entering suspend" >> ${LOGFILE}
	echo 1 > /sys/class/gpio/gpio${AP_READY}/value
elif [ "${1}" == "post" ]; then
	# After wakeup
	echo 0 > /sys/class/gpio/gpio${AP_READY}/value
	NOW=`date`
	echo "$NOW Exiting suspend" >> ${LOGFILE}
fi
