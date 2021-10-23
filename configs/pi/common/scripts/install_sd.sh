#!/bin/bash

# ensure we don't use the buildroot host path "mount"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
if [ $EUID != 0 ]; then
  echo "This script requires root, we are UID $EUID - it might not work."
fi

set -e
source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh
if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
  exit 1
fi

if [ ! -b "$PI_SD" ]; then
  echo "$PI_SD is not a block device or doesn't exist."
  exit 1
fi

echo "Using configuration at $pi_config_txt"

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
  PI_SD_SFX=${PI_SD}p
fi

outp_path="${BUILDROOT_DIR}/output"
uimg_path="${outp_path}/images/zImage"
cpio_path="${outp_path}/images/rootfs.cpio.lz4"
firm_path="${outp_path}/images/rpi-firmware"

if [ ! -f "$uimg_path" ]; then
  uimg_path="${outp_path}/images/Image"
fi

if [ ! -f "$uimg_path" ]; then
  echo "zImage not found, make sure Buildroot is done compiling."
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
echo "Mounting ${PI_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${PI_SD_SFX}1 $boot_dir

echo "Mounting ${PI_SD_SFX}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
mount ${PI_SD_SFX}2 $rootfs_dir

echo "Mounting ${PI_SD_SFX}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${PI_SD_SFX}3 $persist_dir

echo "Copying kernel..."
rsync -v $uimg_path $boot_dir/
sync

echo "Copying rpi-firmware..."
rsync -rav --no-perms --no-owner --no-group $firm_path/ $boot_dir/
sync

echo "Copying rpi-firmware touchups..."
cp $pi_config_txt $boot_dir/config.txt
cp $pi_cmdline_txt $boot_dir/cmdline.txt
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

echo "Copying device tree(s)..."
rsync -rav --no-perms --no-owner --no-group $outp_path/images/*.dtb $boot_dir/
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $cpio_path $boot_dir/rootfs.cpio.lz4
sync

cleanup
