#!/bin/bash

# ensure we don't use the buildroot host path "mount"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
if [ "$EUID" != 0 ]; then
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

OUTPUT_DIR="${BUILDROOT_DIR}"
IMAGES_DIR="${OUTPUT_DIR}/images"
UIMG_PATH="${IMAGES_DIR}/bzImage"
CPIO_DIR="${IMAGES_DIR}/rootfs.cpio.lz4"
SKIFF_INIT_DIR="${IMAGES_DIR}/skiff-init"
SQUASHFS_PATH="${IMAGES_DIR}/rootfs.squashfs"
ROOTFS_PART_DIR="${IMAGES_DIR}/rootfs_part"
PERSIST_PART_DIR="${IMAGES_DIR}/persist_part"
BOOT_PART_DIR="${IMAGES_DIR}/boot_part"

if [ ! -f "$UIMG_PATH" ]; then
  echo "bzImage not found, make sure Buildroot is done compiling."
  exit 1
fi
if [ ! -f "$SQUASHFS_PATH" ]; then
  echo "rootfs.squashfs not found, make sure Buildroot is done compiling."
  exit 1
fi
if [ ! -f "${SKIFF_INIT_DIR}/skiff-init-squashfs" ]; then
  echo "skiff-init-squashfs not found, make sure Buildroot is done compiling."
  exit 1
fi

mounts=()
MOUNTS_DIR=${OUTPUT_DIR}/mounts
mkdir -p ${MOUNTS_DIR}
WORK_DIR=$(mktemp -d -p "${MOUNTS_DIR}")
RS="rsync -rav --no-perms --no-owner --no-group --progress --inplace"

# deletes the temp directory
cleanup() {
  sync || true
  for mount in "${mounts[@]}"; do
    echo "Unmounting ${mount}..."
    umount "$mount" || true
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

install_slot() {
  local next_dir="${BOOT_DIR}/.next"

  rm -rf "$next_dir"
  mkdir -p "$next_dir"
  echo "Copying kernel to next boot slot..."
  ${RS} "$UIMG_PATH" "$next_dir/bzImage"
  echo "Copying squashfs to next boot slot..."
  ${RS} "$SQUASHFS_PATH" "$next_dir/init-skiffos.squashfs"
  echo "Copying skiff-init to next boot slot..."
  ${RS} "${SKIFF_INIT_DIR}/" "$next_dir/skiff-init/"
  sync

  if [ -d "${BOOT_DIR}/previous" ]; then
    mv "${BOOT_DIR}/previous" "${BOOT_DIR}/.old-previous"
  fi
  if [ -d "${BOOT_DIR}/current" ]; then
    mv "${BOOT_DIR}/current" "${BOOT_DIR}/previous"
  else
    cp -a "$next_dir" "${BOOT_DIR}/previous"
  fi
  mv "$next_dir" "${BOOT_DIR}/current"
  rm -rf "${BOOT_DIR}/.old-previous"
  sync
}

echo "Mounting ${INTEL_DESKTOP_PARTITION} to $PERSIST_DIR..."
mkdir -p "$PERSIST_DIR"
mounts+=("$PERSIST_DIR")
mount "$INTEL_DESKTOP_PARTITION" "$PERSIST_DIR"
mkdir -p "$BOOT_DIR"

install_slot

if [ -d "${BOOT_PART_DIR}" ]; then
    echo "Copying boot_part..."
    ${RS} "${BOOT_PART_DIR}/" "${BOOT_DIR}/"
    sync
fi

if [ -d "${ROOTFS_PART_DIR}" ]; then
  echo "Copying rootfs_part..."
  mkdir -p "${ROOTFS_DIR}"
  ${RS} "${ROOTFS_PART_DIR}/" "${ROOTFS_DIR}/"
  sync
fi

if [ -d "${PERSIST_PART_DIR}" ]; then
  echo "Copying persist_part..."
  ${RS} "${PERSIST_PART_DIR}/" "${PERSIST_DIR}/"
  sync
fi

if [ -f "${CPIO_DIR}" ]; then
  echo "Copying initrd..."
  ${RS} "$CPIO_DIR" "$BOOT_DIR/initrd-skiffos"
  sync
fi

if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
    PERSIST_SWAP=${PERSIST_DIR}/primary.swap
    if [ ! -f "${PERSIST_SWAP}" ]; then
        echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
        dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
    fi
fi

sync
cleanup
