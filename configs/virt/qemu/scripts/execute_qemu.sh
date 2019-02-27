#!/bin/sh

IMAGES_DIR=$BUILDROOT_DIR/output/images
QEMU_DIR=${IMAGES_DIR}/qemu
ROOTFS_IMAGE=${QEMU_DIR}/qemu-image.img
ROOTFS_DISK=${QEMU_DIR}/qemu-persist.qcow2
GENIMAGE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/qemu-genimage.cfg
GENIMAGE_TMP=${QEMU_DIR}/genimage.tmp

mkdir -p ${QEMU_DIR}
cd ${IMAGES_DIR}
if [ ! -f ${ROOTFS_IMAGE} ]; then
	mkdir -p ${QEMU_DIR}/fakeroot
	echo "Building qemu root image..."
  # Format the image
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

if [ ! -f ${ROOTFS_DISK} ]; then
    # Sparse/dynamically allocated image
    qemu-img convert -f raw -O qcow2 ${ROOTFS_IMAGE} ${ROOTFS_DISK}
fi

qemu-system-x86_64 \
	-kernel bzImage \
	-initrd rootfs.cpio.gz -m size=512 \
	-append "nokaslr norandmaps console=tty root=/dev/ram0" \
	-drive file=${ROOTFS_DISK},if=virtio \
	-net nic,model=virtio \
	-net user \
	-cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
