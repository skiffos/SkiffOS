#!/bin/bash

OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output"
IMAGES_DIR="${OUTPUT_DIR}/images"

echo "Copying u-boot binary blobs..."
rsync -rv ${SKIFF_CURRENT_CONF_DIR}/resources/sd_fuse/ ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/bl1-emmcboot.img ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/bl1-sdboot.img ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/partmap_emmc.txt ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/

echo "Building modules image..."
mkdir -p ${IMAGES_DIR}/modules
rsync -rv --remove-source-files ${OUTPUT_DIR}/target/lib/modules/ ${IMAGES_DIR}/modules/
rm -rf ${OUTPUT_DIR}/target/lib/modules/*
dd if=/dev/zero of=${IMAGES_DIR}/modules.img bs=1M count=100
genext2fs -b 16384 -d ${IMAGES_DIR}/modules -o linux ${IMAGES_DIR}/modules.img
e2label ${IMAGES_DIR}/modules.img modules
