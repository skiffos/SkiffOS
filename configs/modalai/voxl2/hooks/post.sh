#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
HOST_DIR=${SKIFF_BUILDROOT_DIR}/host
SYSFS_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/sysfs
BOOT_DIR=${SYSFS_DIR}/boot
ROOTFS_DIR=${BOOT_DIR}
BOOT_IMAGE=${IMAGES_DIR}/apq8096-boot.img
SKIFF_IMAGE=${IMAGES_DIR}/apq8096-sysfs.ext4.img
SPARSE_SKIFF_IMAGE=${IMAGES_DIR}/apq8096-sysfs.ext4

if [ -f ${SKIFF_IMAGE} ]; then
    rm -f ${SKIFF_IMAGE}
fi
if [ -f ${SPARSE_SKIFF_IMAGE} ]; then
    rm -f ${SPARSE_SKIFF_IMAGE} || true
fi

mkdir -p ${SYSFS_DIR}
cd ${SYSFS_DIR}
mkdir -p bin dev etc lib mnt proc sbin sys tmp var

cd ${IMAGES_DIR}
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    rsync -rav ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    rsync -rav ${IMAGES_DIR}/persist_part/ ${SYSFS_DIR}/
fi
rsync -rv ./skiff-init/ ${BOOT_DIR}/skiff-init/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ./skiff-init/resize2fs.conf
rsync -rv \
  ./*.dtb ./*Image* \
  ./skiff-release ./rootfs.squashfs \
  ${BOOT_DIR}/

# boot symlinks
ln -fs /boot/skiff-init/skiff-init-squashfs ${SYSFS_DIR}/init
ln -fs /boot/skiff-init/skiff-init-squashfs ${SYSFS_DIR}/sbin/init
mkdir -p ${SYSFS_DIR}/lib/systemd
ln -fs /boot/skiff-init/skiff-init-squashfs ${SYSFS_DIR}/lib/systemd/systemd

# create sysfs.ext4
echo "Building system image..."

# use android ext4 fs
if [ -f ${SKIFF_IMAGE} ]; then
    rm ${SKIFF_IMAGE}
fi
# ${HOST_DIR}/bin/make_ext4fs \
#            -b 4096 \
#            -L "sysfs" \
#            -l "1.6G" \
#            ${SKIFF_IMAGE} ${SYSFS_DIR}

# NOTE: does not work with current modalai kernel w/ journal error
# OLD: 524288000 bytes / 4096 = 128000 blocks
# -U "57f8f4bc-abf4-655f-bf67-946fc0f9f25b"
 ${HOST_DIR}/sbin/mkfs.ext4 \
            -d ${SYSFS_DIR} \
            -b 4096 \
            -L "sysfs" \
            -O "^has_journal" \
            ${SKIFF_IMAGE} "1G"
# mv ${SKIFF_IMAGE} ${SPARSE_SKIFF_IMAGE}

# make it sparse
echo "Generating sparse $(basename ${SPARSE_SKIFF_IMAGE})..."
if [ -f ${SPARSE_SKIFF_IMAGE} ]; then
    rm ${SPARSE_SKIFF_IMAGE}
fi
${HOST_DIR}/bin/img2simg \
           ${SKIFF_IMAGE} \
           ${SPARSE_SKIFF_IMAGE} \
           4096
# delete old raw image
rm ${SKIFF_IMAGE} || true

# create kernel image
echo "Generating Image.gz+dtb..."
cat ./Image.gz ./m0054-qrb5165-iot-rb5.dtb > Image.gz+dtb

# create boot image
echo "Generating $(basename ${BOOT_IMAGE})..."

KERNEL_CMDLINE="noinitrd earlycon=msm_geni_serial,0xa90000 console=ttyMSM0,115200,n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 rw rootwait rootfstype=ext4 init=/boot/skiff-init/skiff-init-squashfs audit=0 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 cgroup.memory=nokmem,nosocket swiotlb=2048 reboot=panic_warm net.ifnames=0 fsck.mode=force fsck.repair=yes"
${HOST_DIR}/bin/mkbootimg \
           --kernel "Image.gz+dtb" \
           --pagesize 4096 \
           --base "0x80000000" \
           --second_offset "0x00f00000" \
           --tags_offset "0x81900000" \
           --cmdline "${KERNEL_CMDLINE}" \
           -o ${BOOT_IMAGE}
