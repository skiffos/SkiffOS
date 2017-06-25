#!/bin/bash
set -eo pipefail

BLOB_DIR="${SKIFF_CURRENT_CONF_DIR}/resources/uboot"
OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output"
UBOOT_DIR="${OUTPUT_DIR}/build/uboot-custom"
IMAGES_DIR="${OUTPUT_DIR}/images"
BASE_MACH="s5p6818"
BOARD_NAME="artik710"
FIP_LOAD_ADDR="0x7df00000"
BL2_LOAD_ADDR="0x7fc00000"
BL2_JUMP_ADDR="0x7fe00000"
OBJCOPY=aarch64-linux-objcopy
SKIP_BOOT_SIZE=4
BOOT_SIZE=150
ROOTFS_SIZE=150
PERSIST_INIT_SIZE=300
MODULE_SIZE=32
BOOT_USE_VFAT="" # set to yes if needed

if [ ! -d "$UBOOT_DIR" ]; then
  echo "Uboot expected at $UBOOT_DIR but not found."
  exit 1
fi

cd $UBOOT_DIR

echo "Generating env..."
cp `find . -name "env_common.o"` copy_env_common.o
${OBJCOPY} -O binary --only-section=.rodata.default_environment copy_env_common.o
tr '\0' '\n' < copy_env_common.o | grep '=' > default_envs_sd.txt
sed -i "s/^ramdiskaddr=.*/ramdiskaddr=0x4A000000/" default_envs_sd.txt
sed -i "s/^fdtaddr=.*/fdtaddr=0x49000000/" default_envs_sd.txt
sed -i "s/^ramdisk_file=.*/ramdisk_file=rootfs.cpio.uboot/" default_envs_sd.txt
cp default_envs_sd.txt default_envs_emmc.txt
sed -i "s/^bootcmd=.*/bootcmd=run sdboot/" default_envs_sd.txt
sed -i "s/^bootcmd=.*/bootcmd=run ramfsboot/" default_envs_emmc.txt
sed -i '/rootdev=[0-9]\{1\}/{s//rootdev=1/;h};${x;/./{x;q0};x;q1}' default_envs_sd.txt
sed -i "s#^load_args=.*#load_args=run factory_load; setenv bootargs \${console} net.ifnames=0 no_console_suspend \${opts} \${recoverymode} drm_panel=\${lcd_panel}#g" default_envs_emmc.txt
tools/mkenvimage -s 16384 -o params_emmc.bin default_envs_emmc.txt
tools/mkenvimage -s 16384 -o params_sd.bin default_envs_sd.txt
cp params_sd.bin params_emmc.bin ${IMAGES_DIR}/

echo "Generating FIP nonsecure image..."
tools/fip_create/fip_create --dump --bl33 u-boot.bin fip-nonsecure.bin
tools/nexell/SECURE_BINGEN -c ${BASE_MACH} \
                           -t 3rdboot \
                           -n ${UBOOT_DIR}/tools/nexell/nsih/raptor-64.txt \
                           -i fip-nonsecure.bin -o fip-nonsecure.img \
                           -l ${FIP_LOAD_ADDR} -e 0x00000000

#echo "Generating device FIP image..."
#tools/fip_create/fip_create --dump --bl2 ${BLOB_DIR}/fip-loader-sd.img --bl31 ${BLOB_DIR}/fip-secure.img --bl33 ${IMAGES_DIR}/u-boot.bin ${IMAGES_DIR}/fip.bin

cp ${BLOB_DIR}/fip-secure.img \
   ${BLOB_DIR}/fip-nonsecure.bin \
   ${BLOB_DIR}/fip-loader-emmc.img \
   ${IMAGES_DIR}

# echo "Generating single-file bootloader images..."
# dd if=/dev/zero ibs=1024 count=2050 of=${IMAGES_DIR}/singleimage.bin
# dd if=${IMAGES_DIR}/fip.bin of=${IMAGES_DIR}/singleimage.bin conv=notrunc
# cat ${BLOB_DIR}/l-loader.bin >> ${IMAGES_DIR}/singleimage.bin
# tools/nexell/BOOT_BINGEN -c ${BASE_MACH} -t 3rdboot -n ${BLOB_DIR}/raptor-emmc-32.txt -i ${IMAGES_DIR}/singleimage.bin -o ${IMAGES_DIR}/singleimage-emmcboot.bin -l ${BL2_LOAD_ADDR} -e ${BL2_JUMP_ADDR}
# tools/nexell/BOOT_BINGEN -c ${BASE_MACH} -t 3rdboot -n ${BLOB_DIR}/raptor-sd-32.txt   -i ${IMAGES_DIR}/singleimage.bin -o ${IMAGES_DIR}/singleimage-sdboot.bin   -l ${BL2_LOAD_ADDR} -e ${BL2_JUMP_ADDR}

echo "Building boot image..."
dd if=/dev/zero bs=1M count=$BOOT_SIZE of=${IMAGES_DIR}/boot.img
if [ -n "$BOOT_USE_VFAT" ]; then
    mkfs.vfat -n boot ${IMAGES_DIR}/boot.img
    mcopy -i ${IMAGES_DIR}/boot.img \
        ${IMAGES_DIR}/Image \
        ${IMAGES_DIR}/rootfs.cpio.uboot \
        ${IMAGES_DIR}/${BASE_MACH}-${BOARD_NAME}-*.dtb \
        ::
else
    if [ -d "{$IMAGES_DIR}/boot" ]; then
        rm -rf ${IMAGES_DIR}/boot
    fi
    mkdir -p ${IMAGES_DIR}/boot
    rsync -rv \
          ${IMAGES_DIR}/Image \
          ${IMAGES_DIR}/rootfs.cpio.uboot \
          ${IMAGES_DIR}/*.dtb \
          ${IMAGES_DIR}/boot/
    genext2fs -b $(( 1000 * ${BOOT_SIZE} )) -d ${IMAGES_DIR}/boot -o linux ${IMAGES_DIR}/boot.img
fi

echo "Building rootfs image..."
if [ -d "{$IMAGES_DIR}/rootfs" ]; then
    rm -rf ${IMAGES_DIR}/rootfs
fi
mkdir -p ${IMAGES_DIR}/rootfs ${IMAGES_DIR}/resources
rsync -rv \
      ${IMAGES_DIR}/resources/ \
      ${IMAGES_DIR}/rootfs/resources/
dd if=/dev/zero bs=1M count=$ROOTFS_SIZE of=${IMAGES_DIR}/rootfs.img
genext2fs -b $(( 1000 * ${ROOTFS_SIZE} )) -d ${IMAGES_DIR}/rootfs -o linux ${IMAGES_DIR}/rootfs.img
e2label ${IMAGES_DIR}/rootfs.img rootfs

echo "Building persist image..."
mkdir -p ${IMAGES_DIR}/persist
dd if=/dev/zero bs=1M count=$PERSIST_INIT_SIZE of=${IMAGES_DIR}/persist.img
genext2fs -b $(( 1000 * ${PERSIST_INIT_SIZE} )) -d ${IMAGES_DIR}/persist -o linux ${IMAGES_DIR}/persist.img
e2label ${IMAGES_DIR}/persist.img persist
