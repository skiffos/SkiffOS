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
IMAGES_DIR=${BUILDROOT_DIR}/images

img_path="${IMAGES_DIR}/Image"
zimg_path="${IMAGES_DIR}/zImage"
uinit_path="${IMAGES_DIR}/rootfs.cpio.uboot"
dtb_path=$(find ${IMAGES_DIR}/ -name '*.dtb' -print -quit)

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

WORK_DIR=`mktemp -d -p "$DIR"`
RS="rsync -rav --no-perms --no-owner --no-group --progress --inplace"

mounts=()
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

PINE64_SD_SFX=$PINE64_SD
if [ -b ${PINE64_SD}p1 ]; then
    PINE64_SD_SFX=${PINE64_SD}p
fi

mount_persist_dir="${WORK_DIR}/persist"
BOOT_DIR=${mount_persist_dir}/boot
ROOTFS_DIR=${mount_persist_dir}/rootfs
PERSIST_DIR=${mount_persist_dir}/

echo "Mounting ${PINE64_SD_SFX}1 to $mount_persist_dir..."
mkdir -p $mount_persist_dir
mounts+=("$mount_persist_dir")
sudo mount ${PINE64_SD_SFX}1 $mount_persist_dir

echo "Copying files..."

cd ${IMAGES_DIR}
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    ${RS} ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    ${RS} ${IMAGES_DIR}/persist_part/ ${PERSIST_DIR}/
fi
${RS} ./skiff-init/ ${BOOT_DIR}/skiff-init/
${RS} \
      ./*.dtb ./Image \
      ./skiff-release ./rootfs.squashfs \
      ${BOOT_DIR}/

enable_silent() {
  if [ -f "$IMAGES_DIR/.disable-serial-console" ]; then
    echo "Disabling serial console and enabling silent mode..."
    sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
  fi
}

if [ -n "$boot_conf_extlinux" ]; then
    mkdir -p $BOOT_DIR/extlinux
    cp -v $boot_conf_extlinux $BOOT_DIR/extlinux/extlinux.conf
else
    echo "Compiling boot.txt..."
    cp $boot_conf $BOOT_DIR/boot.txt
    enable_silent $BOOT_DIR/boot.txt
    mkimage -A arm -C none -T script -n 'SkiffOS' -d ${BOOT_DIR}/boot.txt ${PERSIST_DIR}/boot.scr
fi

if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
    PERSIST_SWAP=${PERSIST_DIR}/primary.swap
    if [ ! -f ${PERSIST_SWAP} ]; then
        echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
        dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
    else
        echo "Swapfile already exists, skipping allocation step."
    fi
fi
