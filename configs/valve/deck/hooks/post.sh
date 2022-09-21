#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images
REFIND_CONF=${SKIFF_CURRENT_CONF_DIR}/resources/refind.conf

echo "valve/deck: copying refind.conf..."
if [ -d ${IMAGES_DIR}/efi-part/EFI/BOOT ]; then
    cp \
        ${REFIND_CONF} \
        ${IMAGES_DIR}/efi-part/EFI/BOOT/refind.conf
elif [ -d ${IMAGES_DIR}/efi-part/EFI/refind ]; then
    cp \
        ${REFIND_CONF} \
        ${IMAGES_DIR}/efi-part/EFI/refind/refind.conf
fi
