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
