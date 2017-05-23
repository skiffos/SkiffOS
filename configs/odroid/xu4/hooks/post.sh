#!/bin/bash

GENIMAGE=genimage
if ! command -v $GENIMAGE >/dev/null 2>&1; then
  echo "$GENIMAGE is not available, skipping OS image generation."
  exit 0
fi

GENIMAGE_CFG="${SKIFF_CURRENT_CONF_DIR}/resources/genimage/genimage.cfg"
GENIMAGE_TMP="${SKIFF_BUILDROOT_DIR}/output/images/genimage.tmp"
GENIMAGE_FINAL="${SKIFF_BUILDROOT_DIR}/output/images/sdcard.img"
if [ ! -f "$GENIMAGE_CFG" ]; then
  echo "Can't find $GENIMAGE_CFG, skipping image generation."
  exit 0
fi
rm -rf $GENIMAGE_TMP || true

echo "Generating filesystem image..."
# todo: implement gen
