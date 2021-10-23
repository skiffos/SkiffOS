#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e

if [ -z "$SKIFF_PARTITION" ]; then
    echo "Please set SKIFF_PARTITION and try again."
    exit 1
fi

if [ ! -b "$SKIFF_PARTITION" ]; then
  echo "$SKIFF_PARTITION is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"
uimg_path="${images_path}/bzImage"
cpio_path="${images_path}/rootfs.cpio.lz4"

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

mount_dir="${WORK_DIR}/skiff"
boot_dir="${mount_dir}/boot"
rootfs_dir="${mount_dir}"
persist_dir="${mount_dir}"

skiff_release_path="${images_path}/skiff-release"
if [ ! -f "$skiff_release_path" ]; then
    echo "skiff-release not found, make sure Buildroot is done compiling."
    exit 1
fi
skiff_release=$(cat $skiff_release_path | grep "VERSION=" | cut -d= -f2)
# add -1 to the end of the release to avoid refind problems
skiff_release="${skiff_release}-1"

mkdir -p $mount_dir
echo "Mounting ${SKIFF_PARTITION} to $mount_dir..."
mounts+=("$mount_dir")
sudo mount ${SKIFF_PARTITION} $mount_dir

echo "Making boot directory..."
mkdir -p ${boot_dir}

echo "Copying kernel..."
rsync -rav --no-perms --no-owner --no-group $uimg_path $boot_dir/bzImage-skiff-${skiff_release}
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

echo "Copying initrd..."
initrd_filename=initrd-skiff-${skiff_release}
rsync -rav --no-perms --no-owner --no-group $cpio_path $boot_dir/${initrd_filename}
sync

if [ ! -f "$boot_dir/refind_linux.conf" ]; then
    echo "Copying initial refind_linux.conf..."
    cp ${resources_path}/refind_linux.conf ${boot_dir}/refind_linux.conf
fi

cleanup
