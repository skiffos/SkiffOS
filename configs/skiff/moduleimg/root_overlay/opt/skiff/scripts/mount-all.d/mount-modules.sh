#!/bin/bash
set -e

MODULES_IMG=/mnt/rootfs/modules.squashfs
MODULES_MOUNTPOINT=/usr/lib/modules

if mountpoint ${MODULES_MOUNTPOINT} ; then
    echo "Modules already mounted."
    exit 0
fi

if [ ! -f ${MODULES_IMG} ]; then
    echo "Cannot find ${MODULES_IMG}, skipping mount."
    exit 1
fi

echo "Mounting modules from squashfs..."
mount -o loop ${MODULES_IMG} ${MODULES_MOUNTPOINT}
