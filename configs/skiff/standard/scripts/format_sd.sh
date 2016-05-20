#!/bin/bash

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/output/images/u-boot.bin"
ubootimgb="$BUILDROOT_DIR/output/images/u-boot-dtb.bin"
ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse/"
sd_fuse_scr="${BUILDROOT_DIR}/output/images/hk_sd_fuse/sd_fusing.sh"

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! mkfs.msdos -F 32 --help > /dev/null; then
  echo "Please install 'mkfs.msdos' and try again."
  exit 1
fi

if [ ! -f "$sd_fuse_scr" ]; then
  echo "Cannot find $sd_fuse_scr, make sure Buildroot is compiled."
  exit 1
fi

if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgb
fi

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
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

set -x
set -e

echo "Formatting device..."
parted $ODROID_SD mklabel msdos

echo "Making boot partition..."
parted $ODROID_SD mkpart primary fat32 2MiB 50MiB
parted $ODROID_SD set 1 boot on
parted $ODROID_SD set 1 lba on
mkfs.msdos -F 32 ${ODROID_SD}1
mlabel -i ${ODROID_SD}1 ::boot

echo "Making rootfs partition..."
parted $ODROID_SD mkpart primary ext4 50MiB 210MiB
mkfs.ext4 ${ODROID_SD}2
e2label ${ODROID_SD}2 rootfs

echo "Making persist partition..."
parted $ODROID_SD -- mkpart primary ext4 210MiB "-2GiB"
mkfs.ext4 ${ODROID_SD}3
e2label ${ODROID_SD}3 persist

echo "Making swap partition..."

parted $ODROID_SD -- mkpart primary linux-swap "-2Gib" "-0"
mkswap ${ODROID_SD}4
swaplabel -L swap ${ODROID_SD}4

echo "Flashing u-boot..."
cd $ubootscripts
bash ./sd_fusing.sh $ODROID_SD $ubootimg
cd -
