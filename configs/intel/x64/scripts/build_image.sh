#!/bin/sh
set -e

IMAGES_DIR=$BUILDROOT_DIR/output/images
SYS_IMAGE_DIR=${IMAGES_DIR}/sys-image
RESOURCES_DISK=${SYS_IMAGE_DIR}/image-resources.ext4
ROOTFS_DISK=${SYS_IMAGE_DIR}/image-rootfs.img
GENIMAGE_PRE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/pre-genimage.cfg
GENIMAGE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/sys-genimage.cfg
GENIMAGE_TMP=${SYS_IMAGE_DIR}/genimage.tmp


if [ ! -f ${IMAGES_DIR}/bzImage ]; then
  echo "No bzImage found, skipping image build."
  exit 0
fi

mkdir -p ${SYS_IMAGE_DIR} ${IMAGES_DIR}/rootfs_part
cd ${IMAGES_DIR}
rm -rf ${GENIMAGE_TMP}
if [ ! -f ${RESOURCES_DISK} ]; then
	echo "Building resources image..."
	rsync -rav ${IMAGES_DIR}/rootfs.cpio.lz4 ${IMAGES_DIR}/rootfs_part/rootfs.cpio.lz4
	genimage \
		--tmppath "${GENIMAGE_TMP}" \
		--rootpath "${IMAGES_DIR}/rootfs_part" \
		--inputpath "${IMAGES_DIR}" \
		--outputpath "${SYS_IMAGE_DIR}" \
		--config "${GENIMAGE_PRE_CFG}"
	mv ${SYS_IMAGE_DIR}/image-resources.ext2 ${IMAGES_DIR}
	rm -rf ${GENIMAGE_TMP}
fi
if [ ! -f ${ROOTFS_DISK} ]; then
	mkdir -p ${SYS_IMAGE_DIR}/fakeroot
	echo "Building system image..."
	genimage \
		--tmppath "${GENIMAGE_TMP}" \
		--rootpath "${SYS_IMAGE_DIR}/fakeroot" \
		--inputpath "${IMAGES_DIR}" \
		--outputpath "${SYS_IMAGE_DIR}" \
		--config "${GENIMAGE_CFG}"
	rm -rf \
		${SYS_IMAGE_DIR}/fakeroot \
		${SYS_IMAGE_DIR}/efi-part.vfat \
		${SYS_IMAGE_DIR}/image-boot.ext4 \
		${SYS_IMAGE_DIR}/image-persist.ext4 \
		${GENIMAGE_TMP}
fi
