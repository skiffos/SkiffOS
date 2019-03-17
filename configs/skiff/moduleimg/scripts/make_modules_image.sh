#!/bin/bash

set -eo pipefail

OUTPUT_DIR=${SKIFF_BUILDROOT_DIR}/output
TARGET_DIR=${OUTPUT_DIR}/target
IMAGES_DIR=${OUTPUT_DIR}/images
MODULES_DIR=${OUTPUT_DIR}/extra_images/modules
ROOTFS_DIR=${IMAGES_DIR}/rootfs_part
MODULES_IMG=${ROOTFS_DIR}/modules.squashfs

if [ -f ${MODULES_IMG} ]; then
  rm ${MODULES_IMG}
fi

mkdir -p ${MODULES_DIR} ${ROOTFS_DIR}
rsync -rv --remove-source-files ${TARGET_DIR}/usr/lib/modules/ ${MODULES_DIR}/
rm -rf ${TARGET_DIR}/usr/lib/modules/* || true
mkdir -p ${TARGET_DIR}/usr/lib/modules
echo "Module image will be mounted here from rootfs partition." > ${TARGET_DIR}/usr/lib/modules/MOUNTPOINT
cp ${TARGET_DIR}/etc/skiff-release ${MODULES_DIR}/skiff-release
cp ${TARGET_DIR}/etc/buildroot-release ${MODULES_DIR}/buildroot-release
mksquashfs ${MODULES_DIR} ${MODULES_IMG}
