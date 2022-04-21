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

if [ -z "$WANDBOARD_SD" ]; then
  echo "Please set WANDBOARD_SD and try again."
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
  read -p "Verify that '$WANDBOARD_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

ubootimg="$BUILDROOT_DIR/images/u-boot-sunxi-with-spl.bin"
if [ ! -f "$ubootimg" ]; then
    echo "can't find u-boot image at $ubootimg"
    exit 1
fi

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$WANDBOARD_SD bs=8k count=13 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${WANDBOARD_SD} || true
sudo parted $WANDBOARD_SD mklabel msdos
partprobe $WANDBOARD_SD || true

echo "Making persist partition..."
sudo parted -a optimal $WANDBOARD_SD -- mkpart primary ext4 "2048s" "-1s"

echo "Waiting for partprobe..."
sync && sync
partprobe $WANDBOARD_SD || true
sleep 2
partprobe $WANDBOARD_SD || true

WANDBOARD_SD_SFX=$WANDBOARD_SD
if [ -b ${WANDBOARD_SD}p1 ]; then
    WANDBOARD_SD_SFX=${WANDBOARD_SD}p
fi

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${WANDBOARD_SD_SFX}1

partprobe $WANDBOARD_SD || true

sync && sync

echo "Flashing u-boot..."
dd iflag=dsync oflag=dsync if=$ubootimg of=$WANDBOARD_SD seek=8 bs=1024 ${SD_FUSE_DD_ARGS}
sync
