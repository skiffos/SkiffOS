#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if [ -z "$WANDBOARD_SD" ]; then
  echo "Please set WANDBOARD_SD and try again."
  exit 1
fi

if [ ! -b "$WANDBOARD_SD" ]; then
  echo "$WANDBOARD_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/images/u-boot-dtb.img"
bootspl="$BUILDROOT_DIR/images/SPL"

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ ! -f "$bootspl" ]; then
    echo "can't find SPL at $bootspl"
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

MKEXT4="mkfs.ext4 -F"

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$WANDBOARD_SD bs=8k count=13 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${WANDBOARD_SD} || true
sudo parted $WANDBOARD_SD mklabel msdos
partprobe $WANDBOARD_SD || true

echo "Making persist partition..."
sudo parted -a optimal $WANDBOARD_SD -- mkpart primary ext4 128MiB "100%"

echo "Waiting for partprobe..."
sync && sync
partprobe $WANDBOARD_SD || true
sleep 2

WANDBOARD_SD_SFX=$WANDBOARD_SD
if [ -b ${WANDBOARD_SD}p1 ]; then
  WANDBOARD_SD_SFX=${WANDBOARD_SD}p
fi

if [ ! -b ${WANDBOARD_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${WANDBOARD_SD_SFX}."
fi

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${WANDBOARD_SD_SFX}1

sync && sync

echo "Flashing SPL..."
dd iflag=dsync oflag=dsync if=$bootspl of=$WANDBOARD_SD seek=1 bs=1k ${SD_FUSE_DD_ARGS}

echo "Flashing u-boot..."
dd iflag=dsync oflag=dsync if=$ubootimg of=$WANDBOARD_SD seek=69 bs=1k ${SD_FUSE_DD_ARGS}

cd -
