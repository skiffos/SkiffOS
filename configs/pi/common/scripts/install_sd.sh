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
squashfs_path="${outp_path}/images/rootfs.squashfs"
skiff_init_path="${outp_path}/images/skiff-init/"
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
RS="rsync -rav --no-perms --no-owner --no-group --progress --inplace"

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
${RS} $uimg_path $boot_dir/
sync

echo "Copying rpi-firmware..."
${RS} $firm_path/ $boot_dir/
sync

echo "Copying rpi-firmware touchups..."
cp $pi_config_txt $boot_dir/config.txt
cp $pi_cmdline_txt $boot_dir/cmdline.txt
sync

if [ -d "$outp_path/images/boot_part" ]; then
  echo "Copying boot_part..."
  ${RS} $outp_path/images/boot_part/ $boot_dir/
  sync
fi

if [ -d "$outp_path/images/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  ${RS} $outp_path/images/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
  echo "Copying persist_part..."
  ${RS} $outp_path/images/persist_part/ $persist_dir/
  sync
fi

echo "Copying device tree(s)..."
${RS} $outp_path/images/*.dtb $boot_dir/
sync

if [ -f $cpio_path ]; then
  echo "Copying rootfs.cpio.lz4..."
  ${RS} $cpio_path $boot_dir/rootfs.cpio.lz4
  sync
fi

if [ -f $squashfs_path ]; then
  echo "Copying rootfs.squashfs..."
  ${RS} $squashfs_path $boot_dir/rootfs.squashfs
  sync
fi

if [ -d $skiff_init_path ]; then
  echo "Copying skiff-init..."
  ${RS} $skiff_init_path $boot_dir/skiff-init/
  sync
fi

if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
    PERSIST_SWAP=${persist_dir}/primary.swap
    if [ ! -f ${PERSIST_SWAP} ]; then
        echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
        dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
    fi
fi

cleanup
