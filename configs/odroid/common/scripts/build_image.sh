#!/bin/bash
set -eo pipefail

WORK_DIR=`mktemp -d`
EMPTY_WORK_DIR=`mktemp -d`
# deletes the temp directory
function cleanup {
sync || true
if [ -d "$WORK_DIR" ]; then
  rm -rf "$WORK_DIR" || true
fi
if [ -d "$EMPTY_WORK_DIR" ]; then
  rm -rf "$EMPTY_WORK_DIR" || true
fi
}
trap cleanup EXIT

OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output/images"
OUTPUT_IMAGE="${OUTPUT_DIR}/sdcard.img"
OUTPUT_TMP="${OUTPUT_DIR}/tmp.img"
GENIMAGE_CFG="${SKIFF_CURRENT_CONF_DIR}/resources/gen-image/genimage.cfg"

ubootimg="$BUILDROOT_DIR/output/images/u-boot.bin"
ubootimgb="$BUILDROOT_DIR/output/images/u-boot-dtb.bin"
ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse/"

if [ ! -f $ubootimg ]; then
  ubootimg=$ubootimgb
fi

if [ ! -f $ubootimg ]; then
  echo "Cannot find u-boot, make sure Buildroot is done compiling."
  exit 1
fi

img_path="${OUTPUT_DIR}/Image"
zimg_path="${OUTPUT_DIR}/zImage"
dtb_path=$(find ${OUTPUT_DIR}/ -name '*.dtb' -print -quit)

if [ ! -f "$img_path" ]; then
  img_path=$zimg_path
fi

if [ ! -f "$img_path" ]; then
  echo "zImage or Image not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$dtb_path" ]; then
  echo "dtb not found, make sure Buildroot is done compiling."
  exit 1
fi

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

sed -e "s#BOOT_SCRIPT_NAME#$(basename ${boot_conf})#g" \
    -e "s#KERNEL_IMAGE_NAME#$(basename ${img_path})#g" \
    -e "s#DTB_NAME#$(basename ${dtb_path})#g" \
    ${GENIMAGE_CFG} > ${OUTPUT_DIR}/genimage.cfg
cp ${boot_conf} ${OUTPUT_DIR}/

genimage \
  --rootpath "${EMPTY_WORK_DIR}" \
  --tmppath "${OUTPUT_TMP}" \
  --inputpath "${OUTPUT_DIR}" \
  --outputpath "${OUTPUT_DIR}" \
  --config "${OUTPUT_DIR}/genimage.cfg"

echo "Flashing u-boot..."
cd $ubootscripts
SD_FUSE_DD_ARGS="conv=notrunc" ./sd_fusing.sh $OUTPUT_IMAGE $ubootimg
cd -
