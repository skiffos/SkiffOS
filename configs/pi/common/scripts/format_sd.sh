#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! command -v parted >/dev/null 2>&1; then
  echo "Please install 'parted' and try again if this script fails."
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' and try again if this script fails."
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
sudo parted $PI_SD mklabel msdos
sleep 1

echo "Making boot partition..."
sudo parted -a optimal $PI_SD mkpart primary fat16 0% 300M

echo "Making rootfs partition..."
sudo parted -a optimal $PI_SD mkpart primary ext4 300M 700MiB

echo "Making persist partition..."
sudo parted -a optimal $PI_SD -- mkpart primary ext4 700MiB "-1s"

echo "Waiting for partprobe..."
sudo partprobe $PI_SD || true
sleep 2
sudo partprobe $PI_SD || true

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
    PI_SD_SFX=${PI_SD}p
fi

echo "Formatting rootfs partition..."
mkfs.ext4 -F -L "rootfs" -O ^64bit ${PI_SD_SFX}2

echo "Formatting boot partition..."
mkfs.vfat -n BOOT -F 32 ${PI_SD_SFX}1

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" -O ^64bit ${PI_SD_SFX}3

sudo partprobe $PI_SD || true
