#!/bin/bash
set -eo pipefail

ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse"
sd_fuse_scr="${ubootscripts}/sd_fusing.sh"
if [ ! -f "$sd_fuse_scr" ]; then
  echo "Cannot find $sd_fuse_scr, make sure Buildroot is compiled."
  exit 1
fi

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$ODROID_SD bs=1M count=20 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${ODROID_SD} || true

# sudo parted $ODROID_SD mklabel msdos
sudo parted $ODROID_SD mklabel gpt

# boot
sudo parted -a optimal $ODROID_SD mkpart boot ext2 3MiB 2048MiB
sudo parted $ODROID_SD set 1 boot on

# persist
sudo parted -a optimal $ODROID_SD -- mkpart persist ext4 2048MiB "100%"

echo "Waiting for partprobe..."
sync && sync
partprobe $ODROID_SD || true
sleep 2
partprobe $ODROID_SD || true

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

if [ ! -b ${ODROID_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${ODROID_SD_SFX}."
fi

echo "Formatting boot partition..."
mkfs.ext2 -F -L "boot" ${ODROID_SD_SFX}1

echo "Formatting persist partition..."
mkfs.ext4 -F -L "persist" ${ODROID_SD_SFX}2

sync
