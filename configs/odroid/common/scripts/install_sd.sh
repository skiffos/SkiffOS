#!/bin/bash
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -b "$ODROID_SD" ]; then
  echo "$ODROID_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"

img_path="${images_path}/Image"
zimg_path="${images_path}/zImage"
uinit_path="${images_path}/rootfs.cpio.uboot"

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

# verify dtb exists
dtb_path=$(find ${images_path}/ -name '*.dtb' -print -quit)
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

ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse"
sd_install_scr="${ubootscripts}/install_sd.sh"
if [ -f "$sd_install_scr" ]; then
    echo "Using board-specific install_sd.sh"
    source ${sd_install_scr}
    exit 0
fi

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
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

boot_dir="${WORK_DIR}/boot"
rootfs_dir="${WORK_DIR}/rootfs"
persist_dir="${WORK_DIR}/persist"

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

mkdir -p $boot_dir
echo "Mounting ${ODROID_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
sudo mount ${ODROID_SD_SFX}1 $boot_dir

echo "Mounting ${ODROID_SD_SFX}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
sudo mount ${ODROID_SD_SFX}2 $rootfs_dir

echo "Mounting ${ODROID_SD_SFX}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
sudo mount ${ODROID_SD_SFX}3 $persist_dir

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

if [ -n "$boot_conf_enc" ]; then
  echo "Compiling boot.txt..."
  cp $boot_conf $boot_dir/boot.txt
  enable_silent $boot_dir/boot.txt
  mkimage -A arm -C none -T script -n 'Skiff Odroid' -d $boot_dir/boot.txt $boot_dir/boot.scr
else
  echo "Copying boot.ini..."
  cp $boot_conf $boot_dir/boot.ini
  enable_silent $boot_dir/boot.ini
fi
sync

echo "Copying device tree and overlays..."
rsync -rav --no-perms --no-owner --no-group ${images_path}/*.{dtb,dtbo} $boot_dir/
sync

if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
    PERSIST_SWAP=${persist_dir}/primary.swap
    if [ ! -f ${PERSIST_SWAP} ]; then
        echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
        dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
    fi
fi

cleanup
