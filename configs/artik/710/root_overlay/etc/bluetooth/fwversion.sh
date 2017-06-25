#!/bin/sh
btmon > /etc/bluetooth/fwver.txt &
sleep 1
hcitool cmd 04 01
sleep 1
pkill btmon

FIRMWARE=`cat /etc/bluetooth/fwver.txt  | grep -E "Firmware"  | awk '{print $2}'`
BUILD=`cat /etc/bluetooth/fwver.txt  | grep -E "Build"  | awk '{print $2}'`
FULL_FIRMWARE_VER=$FIRMWARE"."$BUILD
cat /etc/bluetooth/fwver.txt
echo "========================================================================="
echo BT_FW=$FULL_FIRMWARE_VER
echo "========================================================================="
