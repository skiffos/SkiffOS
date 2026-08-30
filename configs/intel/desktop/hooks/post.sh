#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images
CLOVER_CONF=${SKIFF_CURRENT_CONF_DIR}/resources/config.plist

if [ -d ${IMAGES_DIR}/efi-part/EFI/CLOVER ]; then
    echo "intel/desktop: copying Clover config.plist..."
    cp \
        ${CLOVER_CONF} \
        ${IMAGES_DIR}/efi-part/EFI/CLOVER/config.plist
fi
