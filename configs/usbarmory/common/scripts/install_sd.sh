#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if [ -z "$USBARMORY_SD" ]; then
  echo "Please set USBARMORY_SD and try again."
  exit 1
fi

if [ ! -b "$USBARMORY_SD" ]; then
  echo "$USBARMORY_SD is not a block device or doesn't exist."
  exit 1
fi

USBARMORY_SD_SFX=$USBARMORY_SD
if [ -b ${USBARMORY_SD}p1 ]; then
  USBARMORY_SD_SFX=${USBARMORY_SD}p
fi

IMAGES_DIR=${BUILDROOT_DIR}/images

if [ ! -f "$IMAGES_DIR/zImage" ]; then
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

mount_persist_dir="${WORK_DIR}/persist"
BOOT_DIR=${mount_persist_dir}/boot
ROOTFS_DIR=${mount_persist_dir}/rootfs
PERSIST_DIR=${mount_persist_dir}/

echo "Mounting ${USBARMORY_SD_SFX}1 to $mount_persist_dir..."
mkdir -p $mount_persist_dir
mounts+=("$mount_persist_dir")
sudo mount ${USBARMORY_SD_SFX}1 $mount_persist_dir

echo "Copying files..."

cd ${IMAGES_DIR}
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    rsync -rav ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    rsync -rav ${IMAGES_DIR}/persist_part/ ${PERSIST_DIR}/
fi
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ./skiff-init/resize2fs.conf
rsync -rv ./skiff-init/ ${BOOT_DIR}/skiff-init/
rsync -rv \
      ./*.dtb ./zImage \
      ./skiff-release ./rootfs.squashfs \
      ${BOOT_DIR}/

PERSIST_SWAP=${PERSIST_DIR}/primary.swap
if [ ! -f ${PERSIST_SWAP} ]; then
    echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
    dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
else
    echo "Swapfile already exists, skipping allocation step."
fi

enable_silent() {
    if [ -f "${IMAGES_DIR}/.disable-serial-console" ]; then
        echo "Disabling serial console and enabling silent mode..."
        sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
    fi
}

echo "Compiling boot.txt..."
cp ${SKIFF_CURRENT_CONF_DIR}/resources/boot-scripts/boot.txt ${BOOT_DIR}/boot.txt
enable_silent ${BOOT_DIR}/boot.txt
mkimage -A arm -C none -T script -n 'SkiffOS' -d ${BOOT_DIR}/boot.txt ${BOOT_DIR}/boot.scr
cd -

cleanup
