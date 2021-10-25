#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' and try again."
  exit 1
fi

if [ -z "$SKIFF_DISK" ]; then
  echo "Please set SKIFF_DISK and try again."
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
  read -p "Verify that '$SKIFF_DISK' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

set -x
set -e

echo "Formatting device..."
parted $SKIFF_DISK mklabel msdos
sleep 1

echo "Making boot partition..."
parted -a optimal $SKIFF_DISK mkpart primary fat16 0% 300M
sleep 1

SKIFF_DISK_SFX=$SKIFF_DISK
if [ -b ${SKIFF_DISK}p1 ]; then
  SKIFF_DISK_SFX=${SKIFF_DISK}p
fi

mkfs.vfat -n BOOT -F 16 ${SKIFF_DISK_SFX}1
parted $SKIFF_DISK set 1 boot on
sleep 1

echo "Making rootfs partition..."
parted -a optimal $SKIFF_DISK mkpart primary ext4 300M 700MiB
sleep 1
mkfs.ext4 -F -L "rootfs" -O ^64bit ${SKIFF_DISK_SFX}2

echo "Making persist partition..."
parted -a optimal $SKIFF_DISK -- mkpart primary ext4 700MiB "-1s"
sleep 1
mkfs.ext4 -F -L "persist" -O ^64bit ${SKIFF_DISK_SFX}3

