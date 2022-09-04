#!/bin/bash
set -eo pipefail

GENIMAGE_TMP=${SKIFF_BUILDROOT_DIR}/extra_images/tmp/genimage
IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
HOST_DIR=${SKIFF_BUILDROOT_DIR}/host
L4T_DIR=${IMAGES_DIR}/linux4tegra
DTB_DIR=${L4T_DIR}/kernel/dtb

# Copy dtbs from linux4tegra.
if [ -d ${IMAGES_DIR}/dtb ]; then
    rm -r ${IMAGES_DIR}/dtb
fi
rsync -rv ${DTB_DIR}/ ${IMAGES_DIR}/dtb/

# EFI Image
ESP_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/esp
ESP_GENIMAGE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/esp-genimage.conf
ESP_IMAGE=${IMAGES_DIR}/jetson-esp.img
if [ -f ${ESP_IMAGE} ]; then
    rm -f ${ESP_IMAGE}
fi

echo "Generating jetson-efi.img..."
mkdir -p ${ESP_DIR}/EFI/BOOT ${GENIMAGE_TMP}
cp ${IMAGES_DIR}/linux4tegra/bootloader/BOOTAA64.efi ${ESP_DIR}/EFI/BOOT/BOOTAA64.efi
${HOST_DIR}/bin/genimage \
		--tmppath "${GENIMAGE_TMP}" \
		--rootpath "${ESP_DIR}" \
		--inputpath "${IMAGES_DIR}" \
		--outputpath "${IMAGES_DIR}" \
		--config "${ESP_GENIMAGE_CFG}"

# create symlinks for system images
ln -fs ${IMAGES_DIR}/jetson-esp.img ${IMAGES_DIR}/linux4tegra/bootloader/esp.img
ln -fs ${IMAGES_DIR}/skiffos.ext2 ${IMAGES_DIR}/linux4tegra/bootloader/system.img

# System image
SKIFF_IMAGE=${IMAGES_DIR}/skiffos.ext2
if [ -f ${SKIFF_IMAGE} ]; then
    rm -f ${SKIFF_IMAGE}
fi

# Make the persist partition
echo "Generating $(basename ${SKIFF_IMAGE})..."
export PERSIST_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/persist
pushd ${IMAGES_DIR}
${SKIFF_CURRENT_CONF_DIR}/scripts/install_to_dir.bash
popd

# Make FS: will be auto resized on first boot
${HOST_DIR}/sbin/mkfs.ext4 \
           -d ${PERSIST_DIR} \
           -L "persist" \
           ${SKIFF_IMAGE} "1024m"
