#!/bin/bash

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
images_path="${outp_path}/images"

img_path="${images_path}/Image"
zimg_path="${images_path}/zImage"
uinit_path="${outp_path}/rootfs.cpio.uboot"
dtb_path=$(find ${images_path}/ -name '*.dtb' -print -quit)
boot_txt="$resources_path/boot-scripts/boot.txt"
boot_ini="$resources_path/boot-scripts/boot.ini"

if [ ! -f $dtb_path ]; then
  echo "dtb not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$img_path" ]; then
  img_path=$zimg_path
fi

if [ ! -f "$img_path" ]; then
  echo "zImage or Image not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$boot_txt"] && [ ! -f "$boot_ini"]; then
  echo "Could not find boot.txt or boot.ini, check $resources_path"
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
persist_dir="${WORK_DIR}/persist"

mkdir -p $boot_dir
echo "Mounting ${ODROID_SD}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${ODROID_SD}1 $boot_dir

echo "Mounting ${ODROID_SD}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
mount ${ODROID_SD}2 $rootfs_dir

echo "Mounting ${ODROID_SD}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${ODROID_SD}3 $persist_dir

echo "Copying kernel image..."
sync
rsync -rav --no-perms --no-owner --no-group $img_path $boot_dir/
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $boot_dir/uInitrd
sync

if [ -d "$outp_path/images/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/persist_part/ $persist_dir/
  sync
fi

if [ -f "$boot_txt"]; then
  echo "Compiling boot.txt..."
  cp $boot_txt $boot_dir/boot.txt
  $mkimage -A arm -C none -T script -n 'Skiff Odroid' -d $boot_dir/boot.txt $boot_dir/boot.scr
else
  echo "Copying boot.ini..."
  cp $boot_ini $boot_dir/boot.ini
fi
sync

echo "Copying device tree..."
rsync -rav --no-perms --no-owner --no-group $dtb_path $boot_dir/devicetree.dtb
sync

cleanup
