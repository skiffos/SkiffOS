#!/bin/bash

export OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output/images"
export UBOOT_IMG="${OUTPUT_DIR}/u-boot.bin"
export UBOOT_SCRIPTS="${BUILDROOT_DIR}/output/images/sd_fuse/"
export UBOOT_FUSE_SCR="${BUILDROOT_DIR}/output/images/sd_fuse/sd_fuse.sh"

# Boot partition size (in kb)
export BOOT_SPACE="300000"
export IMAGE_ALIGNMENT="4096"

# Rootfs partition size (in kb)
export ROOTFS_SIZE="50000"

# Persist partition size (in kb)
export PERSIST_SIZE="300000"

# Align partitions
export BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ALIGNMENT} - 1)
export BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ALIGNMENT})

# Round up RootFS size to the alignment size
export ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE} + ${IMAGE_ALIGNMENT} - 1)
export ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE_ALIGNED} - ${ROOTFS_SIZE_ALIGNED} % ${IMAGE_ALIGNMENT})

# Round up persist size to the alignment size
export PERSIST_SIZE_ALIGNED=$(expr ${PERSIST_SIZE} + ${IMAGE_ALIGNMENT} - 1)
export PERSIST_SIZE_ALIGNED=$(expr ${PERSIST_SIZE_ALIGNED} - ${PERSIST_SIZE_ALIGNED} % ${IMAGE_ALIGNMENT})
export IMG_SIZE=$(expr ${IMAGE_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + ${ROOTFS_SIZE_ALIGNED} + ${PERSIST_SIZE_ALIGNED})

export ROOTFS_PARTITION_START=$(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT})
export ROOTFS_PARTITION_END=$(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT} \+ ${ROOTFS_SIZE_ALIGNED})
