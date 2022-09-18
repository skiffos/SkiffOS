#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

echo "valve/deck: copying refind.conf..."
cp \
    ${SKIFF_CURRENT_CONF_DIR}/resources/refind.conf \
    ${IMAGES_DIR}/efi-part/refind/EFI/BOOT/refind.conf
