#!/bin/bash
set -eo pipefail

BLOB_DIR="${SKIFF_CURRENT_CONF_DIR}/resources/uboot"
OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output"
UBOOT_DIR="${OUTPUT_DIR}/build/uboot-custom"
IMAGES_DIR="${OUTPUT_DIR}/images"
BASE_MACH="s5p6818"
FIP_LOAD_ADDR="0x7df00000"
BL2_LOAD_ADDR="0x7fc00000"
BL2_JUMP_ADDR="0x7fe00000"
OBJCOPY=aarch64-linux-objcopy

if [ ! -d "$UBOOT_DIR" ]; then
  echo "Uboot expected at $UBOOT_DIR but not found."
  exit 1
fi

cd $UBOOT_DIR

echo "Generating env..."
cp `find . -name "env_common.o"` copy_env_common.o
${OBJCOPY} -O binary --only-section=.rodata.default_environment copy_env_common.o
sed -i '/rootdev=[0-9]\{1\}/{s//rootdev=1/;h};${x;/./{x;q0};x;q1}' default_envs_sd.txt
sed -i "s/^bootcmd=.*/bootcmd=run mmcboot/" default_envs_emmc.txt
sed -i "s/^bootcmd=.*/bootcmd=run mmcboot/" default_envs_sd.txt
tools/mkenvimage -s 16384 -o params_emmc.bin default_envs_emmc.txt
tools/mkenvimage -s 16384 -o params_sd.bin default_envs_sd.txt

echo "Generating FIP nonsecure image..."
tools/fip_create/fip_create --dump --bl33 u-boot.bin fip-nonsecure.bin
tools/nexell/SECURE_BINGEN -c ${BASE_MACH} -t 3rdboot -n ${UBOOT_DIR}/tools/nexell/nsih/raptor-64.txt -i fip-nonsecure.bin -o fip-nonsecure.img -l ${FIP_LOAD_ADDR} -e 0x00000000
cp fip-nonsecure.bin ${IMAGES_DIR}/fip-nonsecure.bin

echo "Generating device FIP image..."
tools/fip_create/fip_create --dump --bl2 ${BLOB_DIR}/fip-loader-sd.img --bl31 ${BLOB_DIR}/fip-secure.img --bl33 ${IMAGES_DIR}/u-boot.bin ${IMAGES_DIR}/fip.bin

echo "Generating single-file bootloader images..."
dd if=/dev/zero ibs=1024 count=2050 of=${IMAGES_DIR}/singleimage.bin
dd if=${IMAGES_DIR}/fip.bin of=${IMAGES_DIR}/singleimage.bin conv=notrunc
cat ${BLOB_DIR}/l-loader.bin >> ${IMAGES_DIR}/singleimage.bin
tools/nexell/BOOT_BINGEN -c ${BASE_MACH} -t 3rdboot -n ${BLOB_DIR}/raptor-emmc-32.txt -i ${IMAGES_DIR}/singleimage.bin -o ${IMAGES_DIR}/singleimage-emmcboot.bin -l ${BL2_LOAD_ADDR} -e ${BL2_JUMP_ADDR}
tools/nexell/BOOT_BINGEN -c ${BASE_MACH} -t 3rdboot -n ${BLOB_DIR}/raptor-sd-32.txt   -i ${IMAGES_DIR}/singleimage.bin -o ${IMAGES_DIR}/singleimage-sdboot.bin   -l ${BL2_LOAD_ADDR} -e ${BL2_JUMP_ADDR}
