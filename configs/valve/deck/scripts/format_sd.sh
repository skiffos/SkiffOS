#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if [ -z "$VALVE_DECK_SD" ]; then
  echo "Please set VALVE_DECK_SD and try again."
  exit 1
fi

if [ ! -b "$VALVE_DECK_SD" ]; then
  echo "$VALVE_DECK_SD is not a block device or doesn't exist."
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
  read -p "Verify that '$VALVE_DECK_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F"

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$VALVE_DECK_SD bs=8k count=13 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${VALVE_DECK_SD} || true
sudo parted $VALVE_DECK_SD mklabel msdos
partprobe $VALVE_DECK_SD || true

echo "Making persist partition..."
# note: u-boot.toc1 requires >20MiB free space before persist.
sudo parted -a optimal $VALVE_DECK_SD -- mkpart primary ext4 128MiB "100%"

echo "Waiting for partprobe..."
sync && sync
partprobe $VALVE_DECK_SD || true
sleep 2

VALVE_DECK_SD_SFX=$VALVE_DECK_SD
if [ -b ${VALVE_DECK_SD}p1 ]; then
  VALVE_DECK_SD_SFX=${VALVE_DECK_SD}p
fi

if [ ! -b ${VALVE_DECK_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${VALVE_DECK_SD_SFX}."
fi

if [ -z "$KEEP_PERSIST" ]; then
    echo "Formatting persist partition..."
    mkfs.ext4 -F -L "persist" ${VALVE_DECK_SD_SFX}1
else
    echo "Keeping existing persist partition: KEEP_PERSIST is set."
fi

sync && sync
