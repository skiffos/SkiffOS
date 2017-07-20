#!/bin/bash

echo "Copying sd_fuse blobs..."
rsync -rav $SKIFF_CURRENT_CONF_DIR/resources/sd_fuse/ ./output/images/hk_sd_fuse/
