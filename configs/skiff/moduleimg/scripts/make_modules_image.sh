#!/bin/bash
#
# Moves the kernel modules out of the target into a persistent directory and
# packs that directory as modules.squashfs on the rootfs partition.
#
# The directory persists so an incremental build that reinstalls no modules
# still packs the last ones. When the target holds modules, they name the
# current kernel releases, and the trees of every other release are dropped,
# so a kernel update does not keep packing the old kernel's modules.
#
# Buildroot's depmod indexes only the modules the current build left in the
# target, which after an incremental build may be a single package's, so the
# index is regenerated here over the merged directory before packing.

set -eo pipefail

OUTPUT_DIR=${SKIFF_BUILDROOT_DIR}/output
TARGET_DIR=${OUTPUT_DIR}/target
TARGET_MODULES_DIR=${TARGET_DIR}/usr/lib/modules
IMAGES_DIR=${OUTPUT_DIR}/images
MODULES_BASE_DIR=${OUTPUT_DIR}/extra_images
MODULES_DIR=${MODULES_BASE_DIR}/modules
ROOTFS_DIR=${IMAGES_DIR}/rootfs_part
MODULES_IMG=${ROOTFS_DIR}/modules.squashfs

if [ -f ${MODULES_IMG} ]; then
  rm ${MODULES_IMG}
fi

mkdir -p ${MODULES_DIR} ${ROOTFS_DIR} ${TARGET_MODULES_DIR}

releases=$(find ${TARGET_MODULES_DIR} -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if [ -n "${releases}" ]; then
  for tree in $(find ${MODULES_DIR} -mindepth 1 -maxdepth 1 -type d -printf '%f\n'); do
    if ! grep -qxF "${tree}" <<< "${releases}"; then
      echo "Dropping modules of kernel ${tree}, which this build does not install."
      rm -rf "${MODULES_DIR:?}/${tree}"
    fi
  done
fi

rsync -rv --remove-source-files ${TARGET_MODULES_DIR}/ ${MODULES_DIR}/
rm -rf ${TARGET_MODULES_DIR}/* || true
for release in $(find ${MODULES_DIR} -mindepth 1 -maxdepth 1 -type d -printf '%f\n'); do
  ${OUTPUT_DIR}/host/sbin/depmod -a -b ${MODULES_BASE_DIR} -m /modules "${release}"
done
echo "Module image will be mounted here from rootfs partition." > ${TARGET_MODULES_DIR}/MOUNTPOINT
cp ${TARGET_DIR}/etc/skiff-release ${MODULES_DIR}/skiff-release
cp ${TARGET_DIR}/etc/buildroot-release ${MODULES_DIR}/buildroot-release
mksquashfs ${MODULES_DIR} ${MODULES_IMG}
