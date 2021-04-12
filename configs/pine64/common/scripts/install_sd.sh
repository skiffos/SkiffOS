#!/bin/bash
set -eo pipefail

# ensure we don't use the buildroot host path "mount"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
if [ $EUID != 0 ]; then
  echo "This script requires root, so it might not work."
fi

if [ -z "$PINE64_SD" ]; then
  echo "Please set PINE64_SD and try again."
  exit 1
fi

if [ ! -b "$PINE64_SD" ]; then
  echo "$PINE64_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"

img_path="${images_path}/Image"
zimg_path="${images_path}/zImage"
uinit_path="${images_path}/rootfs.cpio.uboot"
dtb_path=$(find ${images_path}/ -name '*.dtb' -print -quit)

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

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

PINE64_SD_SFX=$PINE64_SD
if [ -b ${PINE64_SD}p1 ]; then
  PINE64_SD_SFX=${PINE64_SD}p
fi

mkdir -p $boot_dir
echo "Mounting ${PINE64_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${PINE64_SD_SFX}1 $boot_dir

echo "Mounting ${PINE64_SD_SFX}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
mount ${PINE64_SD_SFX}2 $rootfs_dir

echo "Mounting ${PINE64_SD_SFX}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${PINE64_SD_SFX}3 $persist_dir

echo "Copying kernel image..."
sync
rsync -rav --no-perms --no-owner --no-group $img_path $boot_dir/
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $boot_dir/rootfs.cpio.uboot
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

enable_silent() {
  if [ -f "$images_path/.disable-serial-console" ]; then
    echo "Disabling serial console and enabling silent mode..."
    sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
  fi
}

if [ -n "$boot_conf_extlinux" ]; then
    mkdir -p $boot_dir/boot/extlinux/
    cp $boot_conf_extlinux $boot_dir/boot/extlinux/extlinux.conf
else
    echo "Compiling boot.txt..."
    cp $boot_conf $boot_dir/boot.txt
    enable_silent $boot_dir/boot.txt
    mkimage -A arm -C none -T script -n 'SkiffOS' -d $boot_dir/boot.txt $boot_dir/boot.scr
fi
sync

echo "Copying device tree..."
rsync -rav --no-perms --no-owner --no-group ${images_path}/*.dtb $boot_dir/
sync

cleanup
