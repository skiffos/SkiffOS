#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

GRUB_CONF=${SKIFF_CURRENT_CONF_DIR}/resources/grub.cfg
if [ -d ${IMAGES_DIR}/efi-part/EFI/BOOT ]; then
    echo "intel/desktop: copying grub.cfg..."
    cp \
        ${GRUB_CONF} \
        ${IMAGES_DIR}/efi-part/EFI/BOOT/grub.cfg
fi

REFIND_CONF=${SKIFF_CURRENT_CONF_DIR}/resources/refind.conf
if [ -d ${IMAGES_DIR}/efi-part/EFI/refind ]; then
    echo "intel/desktop: copying refind.conf..."
    cp \
        ${REFIND_CONF} \
        ${IMAGES_DIR}/efi-part/EFI/refind/refind.conf

    echo "intel/desktop: deleting refind BOOT.CSV..."
    rm -f ${IMAGES_DIR}/efi-part/EFI/refind/BOOT.CSV
fi
