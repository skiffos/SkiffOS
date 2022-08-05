#!/bin/bash
set -e

echo "Probing g_ffs..."
modprobe g_ffs idVendor=0x18d1 idProduct=0x4e42 \
         iSerialNumber="$(hostname)" || true

echo "Mounting functionfs..."
mkdir -p /dev/usb-ffs/adb
mount -t functionfs adb /dev/usb-ffs/adb -o uid=2000,gid=2000 || true

# wait for things to settle
sleep 4
