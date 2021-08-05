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

if [ -z "$USBARMORY_SD" ]; then
  echo "Please set USBARMORY_SD and try again."
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
  read -p "Verify that '$USBARMORY_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

ubootimg="$BUILDROOT_DIR/images/u-boot.imx"
if [ ! -f "$ubootimg" ]; then
    echo "can't find u-boot image at $ubootimg"
    exit 1
fi

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$USBARMORY_SD bs=1M count=8
sync
sleep 1
partprobe $USBARMORY_SD || true

echo "Making partition table..."
sudo parted $USBARMORY_SD mklabel msdos

partprobe $USBARMORY_SD || true
sleep 1

echo "Making persist partition..."
sudo parted -a optimal $USBARMORY_SD -- mkpart primary ext4 "2048s" "-1s"

echo "Waiting for partprobe..."
partprobe $USBARMORY_SD || true
sleep 2
partprobe $USBARMORY_SD || true

USBARMORY_SD_SFX=$USBARMORY_SD
if [ -b ${USBARMORY_SD}p1 ]; then
    USBARMORY_SD_SFX=${USBARMORY_SD}p
fi

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${USBARMORY_SD_SFX}1

partprobe $USBARMORY_SD || true

sync && sync

echo "Flashing u-boot..."
dd iflag=dsync oflag=dsync if=$ubootimg of=$USBARMORY_SD seek=2 bs=512 ${SD_FUSE_DD_ARGS}
sync
