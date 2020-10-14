#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

if [ -z "$NVIDIA_SD" ]; then
  echo "Please set NVIDIA_SD and try again."
  exit 1
fi

if [ ! -b "$NVIDIA_SD" ]; then
  echo "$NVIDIA_SD is not a block device or doesn't exist."
  exit 1
fi

echo "Using configuration at $pi_config_txt"

NVIDIA_SD_SFX=$NVIDIA_SD
if [ -b ${NVIDIA_SD}p1 ]; then
  NVIDIA_SD_SFX=${NVIDIA_SD}p
fi

outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"

uimg_path="${images_path}/Image"
cpio_path="${images_path}/rootfs.cpio.uboot"

enable_silent() {
    if [ -f "$images_path/.disable-serial-console" ]; then
        echo "Disabling serial console and enabling silent mode..."
        sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
    fi
}

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

# nvidia has everything in one partition
#rootfs_dir="${WORK_DIR}/rootfs"
#persist_dir="${WORK_DIR}/persist"
rootfs_dir=$boot_dir
persist_dir=$boot_dir

mkdir -p $boot_dir
echo "Mounting ${NVIDIA_SD_SFX}1 (APP partition) to $boot_dir..."
mounts+=("$boot_dir")
sudo mount ${NVIDIA_SD_SFX}1 $boot_dir

echo "Copying kernel..."
mkdir -p ${boot_dir}/boot
rsync -v $uimg_path $boot_dir/boot/
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

echo "Copying device tree(s)..."
rsync -rav --no-perms --no-owner --no-group $outp_path/images/*.dtb $boot_dir/boot/
# rsync -rav --no-perms --no-owner --no-group $outp_path/images/*.dtb $boot_dir/boot/dtb/
sync

echo "Copying initrd..."
rsync -rav --no-perms --no-owner --no-group $cpio_path $boot_dir/boot/
sync


if [ -n "$boot_conf_enc" ]; then
    echo "Compiling boot.txt..."
    cp $boot_conf $boot_dir/boot/boot.txt
    enable_silent $boot_dir/boot/boot.txt
    if [ -d ${boot_dir}/boot/extlinux ]; then
        rm -rf ${boot_dir}/boot/extlinux || true
    fi
    mkimage -A arm -C none -T script -n 'SkiffOS' -d $boot_dir/boot/boot.txt $boot_dir/boot/boot.scr
elif [ -d $nvidia_extlinux_dir ]; then
    echo "Copying extlinux config..."
    if [ -f ${boot_dir}/boot/boot.scr ]; then
        rm -f ${boot_dir}/boot/boot.scr ${boot_dir}/boot/boot.txt || true
    fi
    rsync -rav --no-perms --no-owner --no-group $nvidia_extlinux_dir/ $boot_dir/boot/extlinux/
fi
sync

cleanup
