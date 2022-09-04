#!/bin/bash
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires root, so it might not work."
  echo "Run in sudo bash if you have any issues."
fi

if [ "$SKIFF_NVIDIA_USB_FLASH" != "confirm" ]; then
    echo "Set SKIFF_NVIDIA_USB_FLASH=confirm to confirm you want to USB-flash to your board."
    echo "Warning: this may overwrite existing data."
    exit 1
fi

IMAGES_DIR=$BUILDROOT_DIR/images

unset ROOTFS_AB
unset ROOTFS_ENC

uimg_path=$IMAGES_DIR/Image
if [ ! -f "$uimg_path" ]; then
  echo "Image not found, make sure Buildroot is done compiling."
  exit 1
fi

flash_path=$IMAGES_DIR/linux4tegra/flash.sh
if [ ! -f $flash_path ]; then
    echo "linux4tegra flash.sh not found, ensure buildroot is done compiling."
    exit 1
fi

cd ${IMAGES_DIR}/linux4tegra

# disable recovery image
export NO_RECOVERY_IMG=1

# using /boot bind-mounted to /mnt/boot
echo "Using skiffos.ext2 as APP partition..."
ln -fs ${IMAGES_DIR}/jetson-esp.img ./bootloader/esp.img
ln -fs ${IMAGES_DIR}/skiffos.ext2 ./bootloader/system.img

# Run the flash script.
export FLASHLIGHT="1"
export NO_RECOVERY_IMG="1"
bash $flash_path -r jetson-agx-orin-devkit mmcblk0p1
