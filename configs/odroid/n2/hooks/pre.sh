#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

echo "Copying sd_fuse script..."
rsync -rav $SKIFF_CURRENT_CONF_DIR/resources/sd_fuse/ $IMAGES_DIR/hk_sd_fuse/
