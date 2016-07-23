#!/bin/bash
set -e

PATH="${BUILDROOT_DIR}/output/host/usr/bin:${BUILDROOT_DIR}/output/host/usr/sbin:/usr/sbin:$PATH"

# Partition size in mb
PART_SIZE="300"

IMAGES_PATH="${BUILDROOT_DIR}/output/images"
BOOT_PATH="${SKIFF_CURRENT_CONF_DIR}/resources/boot-scripts"
GENIMAGE_CFG="${SKIFF_CURRENT_CONF_DIR}/resources/gen-image/genimage.cfg"
GENIMAGE_TMP="${BUILDROOT_DIR}/output/build/genimagetmp"
GENIMAGE_TMP_ROOT="${BUILDROOT_DIR}/output/build/genimagetmproot"

ROOTFS_PATH="${IMAGES_PATH}/rootfs_part"
mkdir -p $ROOTFS_PATH
PERSIST_PATH="${IMAGES_PATH}/persist_part"
mkdir -p $PERSIST_PATH

# Build ext4 images for the two parts
EXT4_OPTS="-G 4 -R 1"
if [ -f $IMAGES_PATH/rootfs.ext4 ]; then
  rm $IMAGES_PATH/rootfs.ext4
fi
mke2img -b 194560 -i 48768 $EXT4_OPTS -d $ROOTFS_PATH -l "rootfs" -o $IMAGES_PATH/rootfs.ext4
if [ -f $IMAGES_PATH/persist.ext4 ]; then
  rm $IMAGES_PATH/persist.ext4
fi
mke2img -B 10000 $EXT4_OPTS -d $PERSIST_PATH -l "persist" -o $IMAGES_PATH/persist.ext4

# Check filesize
ROOTFS_SIZE=$(stat --printf="%s" $IMAGES_PATH/rootfs.ext4)
PERSIST_SIZE=$(stat --printf="%s" $IMAGES_PATH/persist.ext4)

# Round up in megabytes
ROOTFS_SIZE_MB=$(echo "(${ROOTFS_SIZE}/1000000)+2" | bc)
PERSIST_SIZE_MB=$(echo "(${ROOTFS_SIZE}/1000000)+1" | bc)

cp $BOOT_PATH/boot.ini $IMAGES_PATH/boot.ini
if [ -f "$IMAGES_PATH/.disable-serial-console" ]; then
  echo "Disabling serial console..."
  sed -i "/^setenv condev/s/^/# /" $IMAGES_PATH/boot.ini
fi
sed -i "s/uInitrd/rootfs.cpio.uboot/g" $IMAGES_PATH/boot.ini

if [ -d $GENIMAGE_TMP ]; then
  rm -rf $GENIMAGE_TMP
fi
if [ -d $GENIMAGE_TMP_ROOT ]; then
  rm -rf $GENIMAGE_TMP_ROOT
fi
mkdir -p $GENIMAGE_TMP_ROOT

cat ${GENIMAGE_CFG} | sed \
  -e "s/{ROOTFS_SIZE}/${ROOTFS_SIZE_MB}M/g" \
  -e "s/{PERSIST_SIZE}/${PERSIST_SIZE_MB}M/g" \
  > ${IMAGES_PATH}/genimage.cfg

genimage \
	--rootpath "${GENIMAGE_TMP_ROOT}" \
	--tmppath "${GENIMAGE_TMP}"       \
	--inputpath "${IMAGES_PATH}"      \
	--outputpath "${IMAGES_PATH}"     \
	--config "${IMAGES_PATH}/genimage.cfg"

echo "Image built, flashing uboot..."
if [ ! -d $IMAGES_PATH/hk_sd_fuse ]; then
  echo "HK SD FUSE directory not found"
  exit 1
fi

cd ${IMAGES_PATH}/hk_sd_fuse
export SD_FUSE_DD_ARGS="conv=sync,notrunc"
bash ./sd_fusing.sh ${IMAGES_PATH}/sdcard.img
