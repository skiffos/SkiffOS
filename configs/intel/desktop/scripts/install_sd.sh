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

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"
uimg_path="${images_path}/bzImage"
cpio_path="${images_path}/rootfs.cpio.lz4"

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

if [ ! -f "$uimg_path" ]; then
  echo "bzImage not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$cpio_path" ]; then
    echo "rootfs.cpio.lz4 not found, make sure Buildroot is done compiling."
    exit 1
fi

skiff_release_path="${images_path}/skiff-release"
if [ ! -f "$skiff_release_path" ]; then
    echo "skiff-release not found, make sure Buildroot is done compiling."
    exit 1
fi
skiff_release=$(cat $skiff_release_path | grep "VERSION=" | cut -d= -f2)
# add -1 to the end of the release to avoid refind problems
skiff_release="${skiff_release}-1"

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

persist_dir="${WORK_DIR}/persist"
rootfs_dir="${persist_dir}/rootfs"
boot_dir="${persist_dir}/boot"

echo "Mounting ${INTEL_DESKTOP_PARTITION} to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${INTEL_DESKTOP_PARTITION} $persist_dir

echo "Copying kernel..."
mkdir -p ${boot_dir}
${RS} $uimg_path $boot_dir/$(basename $uimg_path)-skiffos-${skiff_release}
sync

if [ -d "${images_path}/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  mkdir -p ${rootfs_dir}
  ${RS} ${images_path}/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "${images_path}/persist_part" ]; then
  echo "Copying persist_part..."
  ${RS} ${images_path}/persist_part/ $persist_dir/
  sync
fi

echo "Copying initrd..."
initrd_filename=initrd-skiffos-${skiff_release}
${RS} $cpio_path $boot_dir/${initrd_filename}
sync

if [ ! -f "${boot_dir}/refind_linux.conf" ]; then
  echo "Copying initial refind_linux.conf..."
  cp ${refind_config} ${boot_dir}/refind_linux.conf
fi

sync
cleanup
