#!/bin/sh
set -e

echo "WIP"
echo "Warning: this does not boot correctly (yet)."
echo "The bootloader needs to be included (grub), then it will."

IMAGES_DIR=$BUILDROOT_DIR/output/images
SYS_IMAGE_DIR=${IMAGES_DIR}/sys-image
ROOTFS_DISK=${SYS_IMAGE_DIR}/image-rootfs.img

mkdir -p ${SYS_IMAGE_DIR}
qemu-img convert \
	-f raw \
 	-O vmdk \
	${ROOTFS_DISK} ${SYS_IMAGE_DIR}/image-rootfs.vmdk

