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
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    rsync -rav ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    rsync -rav ${IMAGES_DIR}/persist_part/ ${PERSIST_DIR}/
fi
rsync -rv ./skiff-init/ ${BOOT_DIR}/skiff-init/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ./skiff-init/resize2fs.conf
rsync -rv \
  ./*.dtb ./Image \
  ./skiff-release ./rootfs.squashfs \
  ${BOOT_DIR}/

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

# will be auto resized on first boot
${HOST_DIR}/sbin/mkfs.ext4 \
           -d ${PERSIST_DIR} \
           -L "persist" \
           ${SKIFF_IMAGE} "1024m"
