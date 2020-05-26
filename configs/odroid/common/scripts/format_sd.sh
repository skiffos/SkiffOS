#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' (usually dosfstools) and try again."
  exit 1
fi

if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/output/images/u-boot.bin"
ubootimgb="$BUILDROOT_DIR/output/images/u-boot-dtb.bin"
ubootimgc="$BUILDROOT_DIR/output/images/u-boot-sunxi-with-spl.bin"
ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse/"
sd_fuse_scr="${ubootscripts}/sd_fusing.sh"

if [ ! -f "$sd_fuse_scr" ]; then
  echo "Cannot find $sd_fuse_scr, make sure Buildroot is compiled."
  exit 1
fi

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgb
fi

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgc
fi

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
  read -p "Verify that '$ODROID_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Formatting device..."
sudo parted $ODROID_SD mklabel msdos

echo "Making boot partition..."
sudo parted -a optimal $ODROID_SD mkpart primary fat32 2MiB 310MiB
sudo parted $ODROID_SD set 1 boot on
sudo parted $ODROID_SD set 1 lba on

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

mkfs.vfat -F 32 ${ODROID_SD_SFX}1
fatlabel ${ODROID_SD_SFX}1 boot

echo "Making rootfs partition..."
sudo parted -a optimal $ODROID_SD mkpart primary ext4 310MiB 600MiB
$MKEXT4 -L "rootfs" ${ODROID_SD_SFX}2

echo "Making persist partition..."
sudo parted -a optimal $ODROID_SD -- mkpart primary ext4 600MiB "-1s"
$MKEXT4 -L "persist" ${ODROID_SD_SFX}3

sync && sync
sleep 1

echo "Flashing u-boot..."
cd $ubootscripts
bash ./sd_fusing.sh $ODROID_SD $ubootimg
cd -
