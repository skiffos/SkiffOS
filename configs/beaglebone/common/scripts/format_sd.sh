#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if [ -z "$BEAGLEBONE_SD" ]; then
  echo "Please set BEAGLEBONE_SD and try again."
  exit 1
fi

if [ ! -b "$BEAGLEBONE_SD" ]; then
  echo "$BEAGLEBONE_SD is not a block device or doesn't exist."
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
  read -p "Verify that '$BEAGLEBONE_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F"

set -x
set -e

# be sure to zero out the old MLO if written.
echo "Formatting device..."
sudo dd if=/dev/zero of=$BEAGLEBONE_SD bs=1M count=12 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${BEAGLEBONE_SD} || true
sudo parted $BEAGLEBONE_SD mklabel msdos
partprobe $BEAGLEBONE_SD || true

echo "Making boot partition..."
sudo parted -a optimal $BEAGLEBONE_SD -- mkpart primary fat32 10MiB 1024MiB
sudo parted $BEAGLEBONE_SD set 1 boot on

echo "Making persist partition..."
sudo parted -a optimal $BEAGLEBONE_SD -- mkpart primary ext4 1024MiB "100%"

echo "Waiting for partprobe..."
sync && sync
partprobe $BEAGLEBONE_SD || true
sleep 2
partprobe $BEAGLEBONE_SD || true

BEAGLEBONE_SD_SFX=$BEAGLEBONE_SD
if [ -b ${BEAGLEBONE_SD}p1 ]; then
  BEAGLEBONE_SD_SFX=${BEAGLEBONE_SD}p
fi

if [ ! -b ${BEAGLEBONE_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${BEAGLEBONE_SD_SFX}."
fi

echo "Formatting boot partition..."
mkfs.vfat -F 32 ${BEAGLEBONE_SD_SFX}1
fatlabel ${BEAGLEBONE_SD_SFX}1 boot

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${BEAGLEBONE_SD_SFX}2

# NOTE: We will use fat32 boot instead: this way we can remote update the MLO & u-boot.
# resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
# ubootimg="$BUILDROOT_DIR/images/u-boot.img"
# bootmlo="$BUILDROOT_DIR/images/MLO"

# if [ ! -f "$ubootimg" ]; then
#     echo "can't find u-boot image at $ubootimg"
#     exit 1
# fi

# if [ ! -f "$bootmlo" ]; then
#     echo "can't find MLO at $bootmlo"
#     exit 1
# fi

# echo "Flashing MLO..."
# dd iflag=dsync oflag=dsync if=$bootmlo of=$BEAGLEBONE_SD bs=512 seek=256 count=256 ${SD_FUSE_DD_ARGS}
# echo "Flashing u-boot..."
# dd iflag=dsync oflag=dsync if=$ubootimg of=$BEAGLEBONE_SD bs=512 seek=768 ${SD_FUSE_DD_ARGS}

sync
