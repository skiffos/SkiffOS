#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ${IMAGES_DIR}/skiff-init/resize2fs.conf

# Build the initrd with skiff-init-squashfs.
INITRD=${IMAGES_DIR}/skiff-init.img
INITRD_TMP=${IMAGES_DIR}/skiff-init.img.tmp
INITRD_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/skiff-init

if [ -d ${INITRD_DIR} ]; then
    rm -rf ${INITRD_DIR}
fi
mkdir -p ${INITRD_DIR}

pushd ${INITRD_DIR}
mkdir -p bin dev etc lib mnt proc sbin sys tmp var
mkdir -p ./boot/skiff-init
rsync -rv ${IMAGES_DIR}/skiff-init/ ./boot/skiff-init/
ln -fs /boot/skiff-init/skiff-init-squashfs ./sbin/init
ln -fs sbin/init ./init
# find . ! -name "*~" | cpio -H newc --create --quiet | lz4 -9 -l > ${INITRD_TMP}
# mkimage -A arm -O linux -T ramdisk -C lz4 -d ${INITRD_TMP} ${INITRD}
find . ! -name "*~" |\
	  LC_ALL=C sort |\
	  cpio --reproducible --verbose -o -H newc |\
    lz4 -9 -l > ${INITRD_TMP}
mkimage -n 'skiff-init-squashfs' -A arm -T ramdisk -C lz4 -d ${INITRD_TMP} ${INITRD}
rm ${INITRD_TMP}
echo "Created skiff-init.img with u-boot header."
popd
