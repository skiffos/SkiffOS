#!/bin/bash

echo "Copying u-boot binary blobs..."
rsync -rv ${SKIFF_CURRENT_CONF_DIR}/resources/sd_fuse/ ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/bl1-emmcboot.img ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/bl1-sdboot.img ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/uboot/partmap_emmc.txt ${SKIFF_BUILDROOT_DIR}/output/images/sd_fuse/
