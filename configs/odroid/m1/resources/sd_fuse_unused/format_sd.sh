#!/bin/bash
set -eo pipefail

ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse"
sd_fuse_scr="${ubootscripts}/sd_fusing.sh"
if [ ! -f "$sd_fuse_scr" ]; then
  echo "Cannot find $sd_fuse_scr, make sure Buildroot is compiled."
  exit 1
fi

ubootimg="${BUILDROOT_DIR}/output/images/u-boot-odroidm1.img"
if [ ! -f "$ubootimg" ]; then
    echo "Cannot find ${ubootimg}, make sure Buildroot is compiled."
    exit 1
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$ODROID_SD bs=1M count=20 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${ODROID_SD} || true

sudo parted $ODROID_SD mklabel gpt

# See https://wiki.odroid.com/odroid-m1/software/building_u-boot#installation_to_memory_card_directly
# CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_USE_PARTITION=y
# CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_PARTITION=1
# CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_PARTITION_NAME="uboot"

# uboot
sudo parted $ODROID_SD mkpart uboot "2048s" "4MiB"
# sudo parted $ODROID_SD set 1 boot on

# boot
sudo parted -a optimal $ODROID_SD mkpart boot fat32 4MiB 2048MiB

# rootfs
# sudo parted -a optimal $ODROID_SD mkpart primary ext4 1024MiB 2048MiB

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

echo "Copying u-boot to u-boot partition..."
dd iflag=dsync oflag=dsync if=${ubootimg} of=${ODROID_SD_SFX}1

echo "Formatting boot partition..."
$MKEXT4 -L "boot" ${ODROID_SD_SFX}2

# echo "Formatting rootfs partition..."
# $MKEXT4 -L "rootfs" ${ODROID_SD_SFX}3

echo "Formatting persist partition..."
$MKEXT4 -L "persist" ${ODROID_SD_SFX}3

sync
