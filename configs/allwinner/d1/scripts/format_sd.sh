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

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/images/u-boot.toc1"
bootspl="$BUILDROOT_DIR/images/boot0_sdcard_sun20iw1p1.bin"

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ ! -f "$bootspl" ]; then
    echo "can't find bootspl image at $bootspl"
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

MKEXT4="mkfs.ext4 -F"

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$ALLWINNER_SD bs=8k count=13 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${ALLWINNER_SD} || true
sudo parted $ALLWINNER_SD mklabel msdos
partprobe $ALLWINNER_SD || true

echo "Making persist partition..."
# note: u-boot.toc1 requires >20MiB free space before persist.
sudo parted -a optimal $ALLWINNER_SD -- mkpart primary ext4 128MiB "100%"

echo "Waiting for partprobe..."
sync && sync
partprobe $ALLWINNER_SD || true
sleep 2
partprobe $ALLWINNER_SD || true

ALLWINNER_SD_SFX=$ALLWINNER_SD
if [ -b ${ALLWINNER_SD}p1 ]; then
  ALLWINNER_SD_SFX=${ALLWINNER_SD}p
fi

if [ ! -b ${ALLWINNER_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${ALLWINNER_SD_SFX}."
fi

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${ALLWINNER_SD_SFX}1

sync && sync

echo "Flashing SPL..."
# note: either location is valid, flash both.
dd iflag=dsync oflag=dsync if=$bootspl of=$ALLWINNER_SD bs=8192 seek=1 ${SD_FUSE_DD_ARGS}
dd iflag=dsync oflag=dsync if=$bootspl of=$ALLWINNER_SD bs=8192 seek=16 ${SD_FUSE_DD_ARGS}

echo "Flashing u-boot..."
# note: the second location is the "backup" location.
dd iflag=dsync oflag=dsync if=$ubootimg of=$ALLWINNER_SD bs=512 seek=32800 ${SD_FUSE_DD_ARGS}
dd iflag=dsync oflag=dsync if=$ubootimg of=$ALLWINNER_SD bs=512 seek=24576 ${SD_FUSE_DD_ARGS}

cd -
