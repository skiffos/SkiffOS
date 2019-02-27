#!/bin/sh

IMAGES_DIR=$BUILDROOT_DIR/output/images
QEMU_DIR=${IMAGES_DIR}/qemu
ROOTFS_DISK=${QEMU_DIR}/qemu-rootfs.img
GENIMAGE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/qemu-genimage.cfg
GENIMAGE_TMP=${QEMU_DIR}/genimage.tmp

mkdir -p ${QEMU_DIR}
cd ${IMAGES_DIR}
if [ ! -f ${ROOTFS_DISK} ]; then
	mkdir -p ${QEMU_DIR}/fakeroot
	echo "Building qemu root disk..."
	genimage \
		--tmppath "${GENIMAGE_TMP}" \
		--rootpath "${QEMU_DIR}/fakeroot" \
		--inputpath "${IMAGES_DIR}" \
		--outputpath "${QEMU_DIR}" \
		--config "${GENIMAGE_CFG}"
	rm -rf \
		${QEMU_DIR}/fakeroot \
		${QEMU_DIR}/qemu-resources.ext4 \
		${QEMU_DIR}/qemu-persist.ext4
fi

qemu-system-x86_64 \
	-kernel bzImage \
	-initrd rootfs.cpio.gz -m size=512 \
	-append "nokaslr norandmaps console=tty root=/dev/ram0" \
	-drive file=${ROOTFS_DISK},if=virtio,format=raw \
	-net nic,model=virtio \
	-net user \
	-cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
