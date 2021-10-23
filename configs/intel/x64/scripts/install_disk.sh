#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e

if [ ! -b "$SKIFF_DISK" ]; then
  echo "$SKIFF_DISK is not a block device or doesn't exist."
  exit 1
fi

SKIFF_DISK_SFX=$SKIFF_DISK
if [ -b ${SKIFF_DISK}p1 ]; then
  SKIFF_DISK_SFX=${SKIFF_DISK}p
fi

outp_path="${BUILDROOT_DIR}/output"
uimg_path="${outp_path}/images/bzImage"
cpio_path="${outp_path}/images/rootfs.cpio.lz4"

if [ ! -f "$uimg_path" ]; then
  echo "bzImage not found, make sure Buildroot is done compiling."
  exit 1
fi

mounts=()
MOUNTS_DIR=${outp_path}/mounts
mkdir -p ${MOUNTS_DIR}
WORK_DIR=`mktemp -d -p "${MOUNTS_DIR}"`

# deletes the temp directory
function cleanup {
sync || true
for mount in "${mounts[@]}"; do
  echo "Unmounting ${mount}..."
  sudo umount $mount || true
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
echo "Mounting ${SKIFF_DISK_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
sudo mount ${SKIFF_DISK_SFX}1 $boot_dir

echo "Mounting ${SKIFF_DISK_SFX}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
sudo mount ${SKIFF_DISK_SFX}2 $rootfs_dir

echo "Mounting ${SKIFF_DISK_SFX}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
sudo mount ${SKIFF_DISK_SFX}3 $persist_dir

echo "Copying kernel..."
rsync -rav --no-perms --no-owner --no-group $uimg_path $boot_dir/bzImage
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

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $cpio_path $boot_dir/rootfs.cpio.lz4
sync

cleanup
