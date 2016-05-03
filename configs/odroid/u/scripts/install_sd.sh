#!/bin/bash

mkimage="$BUILDROOT_DIR/output/host/usr/bin/mkimage"
ubootdir="$BUILDROOT_DIR/output/build/uboot-odroid-v2015.10"
ubootimg="$ubootdir/u-boot.bin"
ubootscripts="$ubootdir/sd_fuse"

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ ! -f "$mkimage" ]; then
  echo "uboot-tools not compiled for host in Buildroot."
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
zimg_path="${outp_path}/images/zImage"
uinit_path="${outp_path}/images/rootfs.cpio.uboot"

if [ ! -f "$zimg_path" ]; then
  echo "zImage not found, make sure Buildroot is done compiling."
  exit 1
fi

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
# deletes the temp directory
function cleanup {
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
mkdir -p $boot_dir
echo "Mounting ${ODROID_SD}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${ODROID_SD}1 $boot_dir

echo "Copying zImage..."
rsync -rav --no-perms --no-owner --no-group $zimg_path $boot_dir/zImage

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $boot_dir/uInitrd

echo "Compiling boot.txt..."
$mkimage -A arm -C none -T script -n 'Skiff Odroid U' -d $resources_path/boot-scripts/boot.txt $boot_dir/boot.scr

cleanup
echo "Flashing u-boot..."
cd $ubootscripts
bash ./sd_fusing.sh $ODROID_SD
cd -
