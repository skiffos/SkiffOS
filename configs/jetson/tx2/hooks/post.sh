#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
HOST_DIR=${SKIFF_BUILDROOT_DIR}/host
PERSIST_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/persist
BOOT_DIR=${PERSIST_DIR}/boot
ROOTFS_DIR=${PERSIST_DIR}/rootfs
SKIFF_IMAGE=${IMAGES_DIR}/skiffos.ext2
if [ -f ${SKIFF_IMAGE} ]; then
    rm -f ${SKIFF_IMAGE}
fi

cd ${IMAGES_DIR}

mkdir -p ${BOOT_DIR}/extlinux ${ROOTFS_DIR}
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    rsync -rav ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    rsync -rav ${IMAGES_DIR}/persist_part/ ${PERSIST_DIR}/
fi
rsync -v \
  ./*.dtb ./Image \
  ./skiff-release ./rootfs.cpio.uboot \
  ${BOOT_DIR}/

cp ${SKIFF_CURRENT_CONF_DIR}/resources/boot-scripts/extlinux.conf \
  ${BOOT_DIR}/extlinux

# will be auto resized on first boot
${HOST_DIR}/sbin/mkfs.ext4 \
           -d ${PERSIST_DIR} \
           -L "persist" \
           ${SKIFF_IMAGE} "1024m"
