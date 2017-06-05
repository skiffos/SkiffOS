#!/bin/bash
set -eo pipefail

source ${SKIFF_CURRENT_CONF_DIR}/scripts/params.sh

if [ -z "$ARTIK_SD" ]; then
  echo "Please set ARTIK_SD and try again."
  exit 1
fi

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will completely destroy all data. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"
IMG=${ARTIK_SD}

echo "Formatting device..."
parted $IMG mklabel msdos

echo "Making boot partition..."
parted -s ${IMG} unit KiB mkpart primary fat32 ${IMAGE_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT})
parted -s ${IMG} set 1 boot on
sleep 1
mkfs.vfat -F 32 ${IMG}1

echo "Making rootfs partition..."
parted -s ${IMG} -- unit KiB mkpart primary ext4 ${ROOTFS_PARTITION_START} ${ROOTFS_PARTITION_END}
sleep 1
$MKEXT4 -L "rootfs" ${ODROID_SD}2

echo "Making persist partition..."
parted -s ${IMG} -- unit KiB mkpart primary ext4 ${ROOTFS_PARTITION_END} -1s
sleep 1
$MKEXT4 -L "persist" ${ODROID_SD}3

sync && sync
sleep 1

echo "Flashing u-boot..."
cd $OUTPUT_DIR/images/sd_fuse
./sd_fuse.sh ${IMG}
