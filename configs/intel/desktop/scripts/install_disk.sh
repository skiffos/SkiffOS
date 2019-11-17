#!/bin/bash
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$INTEL_DESKTOP_PATH" ]; then
  echo "Please set INTEL_DESKTOP_PATH and try again."
  exit 1
fi

if [ ! -d "$INTEL_DESKTOP_PATH" ]; then
  echo "$INTEL_DESKTOP_PATH is not a directory or doesn't exist."
  exit 1
fi

outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"
dest_dir="${INTEL_DESKTOP_PATH}"

img_path="${images_path}/bzImage"
uinit_path="${images_path}/rootfs.cpio.uboot"
dtb_path=$(find ${images_path}/ -name '*.dtb' -print -quit)

if [ ! -f "$img_path" ]; then
  img_path=$zimg_path
fi

if [ ! -f "$img_path" ]; then
  echo "bzImage not found, make sure Buildroot is done compiling."
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

# Collect skiff-release information
skiff_release_path="${images_path}/skiff-release"
if [ ! -f "$skiff_release_path" ]; then
    echo "skiff-release not found, make sure Buildroot is done compiling."
    exit 1
fi

skiff_release=$(cat $skiff_release_path | grep "VERSION=" | cut -d= -f2)

echo "Copying kernel image..."
sync
rsync -rav --no-perms --no-owner --no-group $img_path $dest_dir/bzImage-${skiff_release}
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $dest_dir/unitrd-${skiff_release}
sync

if [ -d "$outp_path/images/rootfs_part" ]; then
  echo "Copying rootfs_part to output opt/skiff-rootfs..."
  mkdir -p $dest_dir/opt/skiff-rootfs/
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/rootfs_part/ $dest_dir/opt/skiff-rootfs/
  sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/persist_part/ $dest_dir/
  sync
fi

if [ -n "${dtb_path}" ]; then
  echo "Copying device tree..."
  rsync -rav --no-perms --no-owner --no-group ${images_path}/*.dtb $boot_dir/
  sync
fi

cleanup
