#!/bin/bash
set -e
env

OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output/images"

IMG="${OUTPUT_DIR}/image_system.img"

BOOT_IMG="${OUTPUT_DIR}/image_boot.img"
ROOTFS_IMG="${OUTPUT_DIR}/image_rootfs.img"
PERSIST_IMG="${OUTPUT_DIR}/image_persist.img"

# Boot partition size (in kb)
BOOT_SPACE="300000"
IMAGE_ALIGNMENT="4096"

# Rootfs partition size (in kb)
ROOTFS_SIZE="50000"

# Persist partition size (in kb)
PERSIST_SIZE="300000"

# UBoot offsets
BL1_OFFSET="1"
BL2_OFFSET="31"
UBOOT_OFFSET="63"
TZSW_OFFSET="719"
UBOOT_PARAMS_OFFSET="1231"
UBOOT_PARAMS="params_sd.bin"

# Align partitions
BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ALIGNMENT} - 1)
BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ALIGNMENT})

# Round up RootFS size to the alignment size
ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE} + ${IMAGE_ALIGNMENT} - 1)
ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE_ALIGNED} - ${ROOTFS_SIZE_ALIGNED} % ${IMAGE_ALIGNMENT})

# Round up persist size to the alignment size
PERSIST_SIZE_ALIGNED=$(expr ${PERSIST_SIZE} + ${IMAGE_ALIGNMENT} - 1)
PERSIST_SIZE_ALIGNED=$(expr ${PERSIST_SIZE_ALIGNED} - ${PERSIST_SIZE_ALIGNED} % ${IMAGE_ALIGNMENT})

IMG_SIZE=$(expr ${IMAGE_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + ${ROOTFS_SIZE_ALIGNED} + ${PERSIST_SIZE_ALIGNED})

echo "Generating boot partition image..."
if [ -f $BOOT_IMG ]; then
  echo "Note: removing old image..."
  rm $BOOT_IMG
fi

cleanup_old_image() {
  echo "Generating $1..."
  if [ -f $2 ]; then
    echo "Note: removing old image..."
    rm $2
  fi
}

allocate_file() {
  if ! fallocate -l ${1}KiB $2 ; then
    echo "Warn: fallocate failed, falling back to dd..."
    dd if=/dev/zero of=${2} bs=1024 count=0 seek=${1}
  fi
}

cleanup_old_image "boot partition image" ${BOOT_IMG}
allocate_file ${BOOT_SPACE_ALIGNED} ${BOOT_IMG}
mkfs.vfat -F 32 ${BOOT_IMG}

cleanup_old_image "rootfs partition image" ${ROOTFS_IMG}
allocate_file ${ROOTFS_SIZE_ALIGNED} ${ROOTFS_IMG}
mkfs.ext2 ${ROOTFS_IMG}

cleanup_old_image "persist partition image" ${PERSIST_IMG}
allocate_file ${PERSIST_SIZE_ALIGNED} ${PERSIST_IMG}
mkfs.ext4 ${PERSIST_IMG}

cleanup_old_image "complete filesystem image" $IMG
allocate_file ${IMG_SIZE} ${IMG}

# Create partition table
parted -s ${IMG} mklabel msdos

# Create boot partition
parted -s ${IMG} unit KiB mkpart primary fat32 ${IMAGE_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT})
parted -s ${IMG} set 1 boot on

# Copy boot partition in
parted ${IMG} unit KiB print
dd conv=notrunc if=${BOOT_IMG} of=${IMG} bs=1KiB count=${BOOT_SPACE_ALIGNED} seek=${IMAGE_ALIGNMENT}

# Create rootfs partition
ROOTFS_PARTITION_START=$(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT})
ROOTFS_PARTITION_END=$(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT} \+ ${ROOTFS_SIZE_ALIGNED})
parted -s ${IMG} -- unit KiB mkpart primary ext4 ${ROOTFS_PARTITION_START} ${ROOTFS_PARTITION_END}

# Copy rootfs partition in
dd conv=notrunc if=${ROOTFS_IMG} of=${IMG} bs=1KiB count=${ROOTFS_SIZE_ALIGNED} seek=${ROOTFS_PARTITION_START}

# Create persist partition
parted -s ${IMG} -- unit KiB mkpart primary ext4 ${ROOTFS_PARTITION_END} -1s

# Copy persist partition in
dd conv=notrunc if=${PERSIST_IMG} of=${IMG} bs=1KiB seek=${ROOTFS_PARTITION_END}
