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

if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
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

set -x
set -e

echo "Formatting device..."
parted $PI_SD mklabel msdos
sleep 1

echo "Making boot partition..."
parted $PI_SD mkpart primary fat16 0 150M
sleep 1

mkfs.vfat -n BOOT -F 16 ${PI_SD}1
parted $PI_SD set 1 boot on
parted $PI_SD set 1 lba on
sleep 1
# mlabel -i ${PI_SD}1 ::boot

echo "Making rootfs partition..."
parted $PI_SD mkpart primary ext4 150M 500MiB
sleep 1
mkfs.ext4 -F -L "rootfs" -O ^64bit ${PI_SD}2

echo "Making persist partition..."
parted $PI_SD -- mkpart primary ext4 500MiB "-1s"
sleep 1
mkfs.ext4 -F -L "persist" -O ^64bit ${PI_SD}3
