#!/bin/bash

set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$PCDUINO_SD" ]; then
  echo "Please set PCDUINO_SD and try again."
  exit 1
fi

if [ ! -b "$PCDUINO_SD" ]; then
  echo "$PCDUINO_SD is not a block device or doesn't exist."
  exit 1
fi

images_path=$BUILDROOT_DIR/output/images
zimg_path=$images_path/zImage
uinit_path=$images_path/rootfs.cpio.uboot
dtb_path=$(find "$images_path/" -name '*.dtb' -print -quit)

source "$SKIFF_CURRENT_CONF_DIR/scripts/determine_config.sh"

if [ ! -f "$dtb_path" ]; then
  echo "dtb not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$zimg_path" ]; then
  echo "zImage not found, make sure Buildroot is done compiling."
  exit 1
fi

WORK_DIR=$(mktemp -d -p "$DIR")

function cleanup() {
  sync || true

  for mount in "${mounts[@]}"; do
    echo "Unmounting $mount..."
    umount "$mount" || true
  done

  if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR" || true
  fi
}
trap cleanup EXIT

boot_dir=$WORK_DIR/boot
rootfs_dir=$WORK_DIR/rootfs
persist_dir=$WORK_DIR/persist

PCDUINO_SD_SFX=$PCDUINO_SD
if [ -b "${PCDUINO_SD}p1" ]; then
  PCDUINO_SD_SFX=${PCDUINO_SD}p
fi

mkdir -p "$boot_dir"
echo "Mounting ${PCDUINO_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount "${PCDUINO_SD_SFX}1" "$boot_dir"

echo "Mounting ${PCDUINO_SD_SFX}2 to $rootfs_dir..."
mkdir -p "$rootfs_dir"
mounts+=("$rootfs_dir")
mount "${PCDUINO_SD_SFX}2" "$rootfs_dir"

echo "Mounting ${PCDUINO_SD_SFX}3 to $persist_dir..."
mkdir -p "$persist_dir"
mounts+=("$persist_dir")
mount "${PCDUINO_SD_SFX}3" "$persist_dir"

echo "Copying kernel image..."
rsync -rav --no-perms --no-owner --no-group "$zimg_path" "$boot_dir/"

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group "$uinit_path" "$boot_dir/rootfs.cpio.uboot"

if [ -d "$images_path/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  rsync -rav --no-perms --no-owner --no-group "$images_path/rootfs_part/" "$rootfs_dir/"
fi

if [ -d "$images_path/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group "$images_path/persist_part/" "$persist_dir/"
fi

echo "Compiling $(basename "$boot_conf")..."
cp "$boot_conf" "$boot_dir/"
mkimage -A arm -C none -T script -d "$boot_dir/$(basename "$boot_conf")" "$boot_dir/boot.scr"

echo "Copying device tree..."
rsync -rav --no-perms --no-owner --no-group $images_path/*.dtb "$boot_dir/"
