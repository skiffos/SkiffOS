#!/bin/sh
set -e

IMAGES_DIR=$BUILDROOT_DIR/output/images
SYS_IMAGE_DIR=${IMAGES_DIR}/sys-image
ROOTFS_DISK=${SYS_IMAGE_DIR}/image-rootfs.img

qemu-img convert \
	-f raw \
 	-O vmdk \
	${ROOTFS_DISK} ${SYS_IMAGE_DIR}/image-rootfs.vmdk

