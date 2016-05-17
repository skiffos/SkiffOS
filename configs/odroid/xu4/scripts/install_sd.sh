#!/bin/bash

mkimage="$BUILDROOT_DIR/output/host/usr/bin/mkimage"

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
uimg_path="${outp_path}/images/zImage.exynos5422-odroidxu4"
uinit_path="${outp_path}/images/rootfs.cpio.uboot"

if [ ! -f "$uimg_path" ]; then
  echo "zImage not found, make sure Buildroot is done compiling."
  exit 1
fi

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
# deletes the temp directory
function cleanup {
  sync || true
  for mount in "${mounts[@]}"; do
    echo "Unmounting ${mount}..."
    umount $mount || true
  done
  mounts=()
  if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR" || true
  fi
}
trap cleanup EXIT

boot_dir="${WORK_DIR}/boot"
rootfs_dir="${WORK_DIR}/rootfs"
mkdir -p $boot_dir
echo "Mounting ${ODROID_SD}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${ODROID_SD}1 $boot_dir

echo "Mounting ${ODROID_SD}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
mount ${ODROID_SD}2 $rootfs_dir

echo "Copying zImage..."
sync
rsync -rav --no-perms --no-owner --no-group $uimg_path $rootfs_dir/zImage
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $rootfs_dir/uInitrd
sync

echo "Copying boot.ini..."
rsync -rav --no-perms --no-owner --no-group $resources_path/boot-scripts/boot.ini $boot_dir/boot.ini
sync

cleanup
