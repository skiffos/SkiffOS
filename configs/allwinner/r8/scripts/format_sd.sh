#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if [ -z "$ALLWINNER_SD" ]; then
  echo "Please set ALLWINNER_SD and try again."
  exit 1
fi

if [ ! -b "$ALLWINNER_SD" ]; then
  echo "$ALLWINNER_SD is not a block device or doesn't exist."
  exit 1
fi

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
  read -p "Verify that '$ALLWINNER_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$ALLWINNER_SD bs=8k count=13 oflag=dsync

echo "Creating partition table..."
sudo partprobe ${ALLWINNER_SD} || true
sudo parted $ALLWINNER_SD mklabel msdos
sudo partprobe $ALLWINNER_SD || true

echo "Making persist partition (starts at 128MiB, after U-Boot SPL area)..."
sudo parted -a optimal $ALLWINNER_SD -- mkpart primary ext4 128MiB "100%"

echo "Waiting for partprobe..."
sync && sync
sudo partprobe $ALLWINNER_SD || true
sleep 2

ALLWINNER_SD_SFX=$ALLWINNER_SD
if [ -b ${ALLWINNER_SD}p1 ]; then
  ALLWINNER_SD_SFX=${ALLWINNER_SD}p
fi

if [ ! -b ${ALLWINNER_SD_SFX}1 ]; then
  echo "Warning: partition device node ${ALLWINNER_SD_SFX}1 not found."
fi

if [ -z "$KEEP_PERSIST" ]; then
  echo "Formatting persist partition..."
  sudo mkfs.ext4 -F -L "persist" ${ALLWINNER_SD_SFX}1
else
  echo "Keeping existing persist partition: KEEP_PERSIST is set."
fi

sync && sync

echo "Flashing u-boot (SPL at offset 8KiB)..."
sudo dd iflag=dsync oflag=dsync if=$ubootimg of=$ALLWINNER_SD bs=1024 seek=8 ${SD_FUSE_DD_ARGS}

echo "Done!"
