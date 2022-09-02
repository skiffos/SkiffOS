#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

echo "valve/deck: copying refind.conf..."
rsync -rav $SKIFF_CURRENT_CONF_DIR/resources/refind.conf $IMAGES_DIR/refind/EFI/BOOT/refind.conf
