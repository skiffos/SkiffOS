#!/bin/bash

# ensure we don't use the buildroot host path "mount"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
if [ $EUID != 0 ]; then
  echo "This script requires root, we are UID $EUID - it might not work."
fi

set -e
if [ -z "$INTEL_DESKTOP_PARTITION" ]; then
  if [ -z "$INTEL_DESKTOP_DISK" ]; then
    echo "Please set INTEL_DESKTOP_DISK or INTEL_DESKTOP_PARTITION and try again."
    exit 1
  fi
  INTEL_DESKTOP_PARTITION="${INTEL_DESKTOP_DISK}2"
  if [ ! -b "$INTEL_DESKTOP_PARTITION" ]; then
    INTEL_DESKTOP_PARTITION="${INTEL_DESKTOP_DISK}p2"
  fi
fi

if [ ! -b "$INTEL_DESKTOP_PARTITION" ]; then
  echo "$INTEL_DESKTOP_PARTITION is not a block device or doesn't exist."
  exit 1
fi

if ! partuuid=$(blkid -o "value" -s "PARTUUID" ${INTEL_DESKTOP_PARTITION}); then
  echo "Unable to determine PARTUUID for ${INTEL_DESKTOP_PARTITION}!"
  exit 1
fi
if [ -z "${partuuid}" ]; then
  echo "Blkid returned empty PARTUUID for ${INTEL_DESKTOP_PARTITION}!"
  exit 1
fi

RESOURCES_DIR="${SKIFF_CURRENT_CONF_DIR}/resources"
OUTPUT_DIR="${BUILDROOT_DIR}"
IMAGES_DIR="${OUTPUT_DIR}/images"
UIMG_PATH="${IMAGES_DIR}/bzImage"
CPIO_DIR="${IMAGES_DIR}/rootfs.cpio.lz4"
SKIFF_INIT_DIR="${IMAGES_DIR}/skiff-init"
SQUASHFS_PATH="${IMAGES_DIR}/rootfs.squashfs"
ROOTFS_PART_DIR="${IMAGES_DIR}/rootfs_part"
PERSIST_PART_DIR="${IMAGES_DIR}/persist_part"
BOOT_PART_DIR="${IMAGES_DIR}/boot_part"

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

if [ ! -f "$UIMG_PATH" ]; then
  echo "bzImage not found, make sure Buildroot is done compiling."
  exit 1
fi

skiff_release_path="${IMAGES_DIR}/skiff-release"
if [ ! -f "$skiff_release_path" ]; then
    echo "skiff-release not found, make sure Buildroot is done compiling."
    exit 1
fi
skiff_release=$(cat $skiff_release_path | grep "VERSION=" | cut -d= -f2)
# add -1 to the end of the release to avoid refind problems
skiff_release="${skiff_release}-1"

mounts=()
MOUNTS_DIR=${OUTPUT_DIR}/mounts
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

PERSIST_DIR="${WORK_DIR}/persist"
ROOTFS_DIR="${PERSIST_DIR}/rootfs"
BOOT_DIR="${PERSIST_DIR}/boot"

echo "Mounting ${INTEL_DESKTOP_PARTITION} to $PERSIST_DIR..."
mkdir -p $PERSIST_DIR
mounts+=("$PERSIST_DIR")
mount ${INTEL_DESKTOP_PARTITION} $PERSIST_DIR

echo "Copying kernel..."
mkdir -p ${BOOT_DIR}
${RS} $UIMG_PATH $BOOT_DIR/$(basename $UIMG_PATH)-skiffos-${skiff_release}
sync

if [ -d "${BOOT_PART_DIR}" ]; then
    echo "Copying boot_part..."
    ${RS} ${BOOT_PART_DIR}/ ${BOOT_DIR}/
    sync
fi

if [ -d "${ROOTFS_PART_DIR}" ]; then
  echo "Copying rootfs_part..."
  mkdir -p ${ROOTFS_DIR}
  ${RS} ${ROOTFS_PART_DIR}/ $ROOTFS_DIR/
  sync
fi

if [ -d "${PERSIST_PART_DIR}" ]; then
  echo "Copying persist_part..."
  ${RS} ${PERSIST_PART_DIR}/ $PERSIST_DIR/
  sync
fi

if [ -f ${CPIO_DIR} ]; then
  echo "Copying initrd..."
  initrd_filename=initrd-skiffos-${skiff_release}
  ${RS} $CPIO_DIR $BOOT_DIR/${initrd_filename}
  sync
fi

if [ -f ${SQUASHFS_PATH} ]; then
  echo "Copying squashfs..."
  squashfs_filename=init-skiffos-${skiff_release}.squashfs
  ${RS} $SQUASHFS_PATH $BOOT_DIR/${squashfs_filename}
  sync
fi

if [ -d $SKIFF_INIT_DIR ]; then
  echo "Copying skiff-init..."
  ${RS} ${SKIFF_INIT_DIR}/ $BOOT_DIR/skiff-init/
  sync
fi

if [ ! -f "${BOOT_DIR}/refind_linux.conf" ]; then
  echo "Copying initial refind_linux.conf..."
  cp ${refind_config} ${BOOT_DIR}/refind_linux.conf
  echo "Setting PARTUUID=${partuuid} in refind_linux.conf..."
  sed -i -e "s/{SKIFFOS_PARTUUID}/${partuuid}/g" ${BOOT_DIR}/refind_linux.conf
fi

sync
cleanup
