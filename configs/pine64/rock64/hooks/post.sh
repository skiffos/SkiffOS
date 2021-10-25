#!/bin/bash
set -eo pipefail

echo "Building rock64 idbloader.img"
IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
MKIMAGE=${SKIFF_BUILDROOT_DIR}/host/bin/mkimage

$MKIMAGE -n rk3328 -T rksd -d ${IMAGES_DIR}/u-boot-tpl.bin ${IMAGES_DIR}/u-boot-tpl.img
cat ${IMAGES_DIR}/u-boot-tpl.img ${IMAGES_DIR}/u-boot-spl.bin > ${IMAGES_DIR}/idbloader.img
