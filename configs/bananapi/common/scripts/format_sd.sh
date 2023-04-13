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

if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
  exit 1
fi

if [ ! -b "$PI_SD" ]; then
  echo "$PI_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/images/u-boot-sunxi-with-spl.bin"

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
  read -p "Verify that '$PI_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Zeroing out partition table..."
sudo dd if=/dev/zero of=${PI_SD} conv=fsync bs=1024 count=4900

echo "Formatting device..."
sudo parted $PI_SD mklabel msdos

echo "Making boot partition..."
sudo parted -a optimal $PI_SD -- mkpart primary fat16 0% 1G

echo "Making persist partition..."
sudo parted -a optimal $PI_SD -- mkpart primary ext4 1G "-1s"

echo "Waiting for partprobe..."
sync && sync
sudo partprobe $PI_SD || true
sleep 2

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
    PI_SD_SFX=${PI_SD}p
fi

echo "Building fat filesystem for boot..."
sudo mkfs.vfat -F 32 ${PI_SD_SFX}1
sudo fatlabel ${PI_SD_SFX}1 boot

echo "Building ext4 filesystem for persist..."
sudo $MKEXT4 -L "persist" ${PI_SD_SFX}2

echo "Flashing u-boot..."
sudo dd if=$ubootimg of=${PI_SD} conv=fsync bs=1024 seek=8

echo "Done!"
