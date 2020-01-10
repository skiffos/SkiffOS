#!/bin/bash

set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$PCENGINES_SD" ]; then
  echo "Please set PCENGINES_SD and try again."
  exit 1
fi

if [ ! -b "$PCENGINES_SD" ]; then
  echo "$PCENGINES_SD is not a block device or doesn't exist."
  exit 1
fi

images_path=$BUILDROOT_DIR/output/images
bzimg_path=$images_path/bzImage
if [ ! -f "$bzimg_path" ]; then
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

PCENGINES_SD_SFX=$PCENGINES_SD
if [ -b "${PCENGINES_SD}p1" ]; then
  PCENGINES_SD_SFX=${PCENGINES_SD}p
fi

mkdir -p "$boot_dir"
echo "Mounting ${PCENGINES_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount "${PCENGINES_SD_SFX}1" "$boot_dir"

echo "Mounting ${PCENGINES_SD_SFX}2 to $rootfs_dir..."
mkdir -p "$rootfs_dir"
mounts+=("$rootfs_dir")
mount "${PCENGINES_SD_SFX}2" "$rootfs_dir"

echo "Mounting ${PCENGINES_SD_SFX}3 to $persist_dir..."
mkdir -p "$persist_dir"
mounts+=("$persist_dir")
mount "${PCENGINES_SD_SFX}3" "$persist_dir"

echo "Copying kernel image..."
rsync -rav --no-perms --no-owner --no-group "$bzimg_path" "$boot_dir/"

if [ -d "$images_path/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  rsync -rav --no-perms --no-owner --no-group "$images_path/rootfs_part/" "$rootfs_dir/"
fi

if [ -d "$images_path/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group "$images_path/persist_part/" "$persist_dir/"
fi

