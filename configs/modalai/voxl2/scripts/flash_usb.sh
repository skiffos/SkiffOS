#!/bin/bash
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires root, so it might not work."
  echo "Run in sudo bash if you have any issues."
fi

IMAGES_DIR=$BUILDROOT_DIR/images
BOOT_IMG_PATH=$IMAGES_DIR/apq8096-boot.img
SYSFS_PATH=$IMAGES_DIR/apq8096-sysfs.ext4
if [ ! -f "$SYSFS_PATH" ]; then
  echo "${SYSFS_PATH} not found."
  echo "Make sure SkiffOS is done compiling and SKIFF_WORKSPACE is set correctly."
  echo "SKIFF_WORKSPACE: ${SKIFF_WORKSPACE}"
  exit 1
fi

cd ${IMAGES_DIR}/

echo "Rebooting to bootloader..."
adb reboot bootloader || true

echo "Flashing apq8096-boot.img..."
fastboot flash boot ${BOOT_IMG_PATH}

echo "Flashing apq8096-sysfs.ext4..."
# fastboot format system || true
# -n 4096
fastboot flash \
         system \
         ${SYSFS_PATH}

echo "Done flashing system image."
fastboot reboot || true
