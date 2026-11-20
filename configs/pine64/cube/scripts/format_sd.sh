#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' (usually dosfstools) and try again."
  exit 1
fi

if [ -z "$PINE64_SD" ]; then
  echo "Please set PINE64_SD and try again."
  exit 1
fi

if [ ! -b "$PINE64_SD" ]; then
  echo "$PINE64_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="${BUILDROOT_DIR}/images/u-boot-sunxi-with-spl.bin"

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will completely destroy all data. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Verify that '$PINE64_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Zeroing out partition table..."
sudo dd if=/dev/zero of=${PINE64_SD} conv=fsync bs=1024 count=4900

echo "Formatting device..."
sudo parted $PINE64_SD mklabel msdos

echo "Making boot partition..."
sudo parted -a optimal $PINE64_SD -- mkpart primary fat16 0% 1G

echo "Making persist partition..."
sudo parted -a optimal $PINE64_SD -- mkpart primary ext4 1G "-1s"

echo "Waiting for partprobe..."
sync && sync
sudo partprobe $PINE64_SD || true
sleep 2

PINE64_SD_SFX=$PINE64_SD
if [ -b ${PINE64_SD}p1 ]; then
    PINE64_SD_SFX=${PINE64_SD}p
fi

echo "Building fat filesystem for boot..."
sudo mkfs.vfat -F 32 ${PINE64_SD_SFX}1
sudo fatlabel ${PINE64_SD_SFX}1 boot

echo "Building ext4 filesystem for persist..."
sudo $MKEXT4 -L "persist" ${PINE64_SD_SFX}2

echo "Flashing u-boot..."
sudo dd if=$ubootimg of=${PINE64_SD} conv=fsync bs=1024 seek=8

sleep 1
sudo partprobe ${PINE64_SD} || true

echo "Done!"
