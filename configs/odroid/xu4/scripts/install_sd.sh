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

if [ ! -f "$mkimage" ]; then
  echo "uboot-tools not compiled for host in Buildroot."
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
uimg_path="${outp_path}/images/zImage"
dtb_path="${outp_path}/images/exynos5422-odroidxu4.dtb"
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

echo "Copying resources..."
mkdir -p $rootfs_dir/resources/
rsync -rav --no-perms --no-owner --no-group $outp_path/images/resources/ $rootfs_dir/resources/
sync

echo "Compiling boot.txt..."
$mkimage -A arm -C none -T script -n 'Skiff Odroid XU4' -d $resources_path/boot-scripts/boot.txt $boot_dir/boot.scr
sync

echo "Copying device tree..."
rsync -rav --no-perms --no-owner --no-group $dtb_path $boot_dir/devicetree.dtb
sync

cleanup
