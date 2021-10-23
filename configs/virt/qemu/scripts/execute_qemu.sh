#!/bin/bash
set -eo pipefail

IMAGES_DIR=$BUILDROOT_DIR/images
QEMU_DIR=${BUILDROOT_DIR}/qemu-exec
ROOTFS_IMAGE=${QEMU_DIR}/qemu-image.img
ROOTFS_DISK=${QEMU_DIR}/qemu-persist.qcow2
SHARED_DIR=${QEMU_DIR}/qemu-shared
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

mkdir -p ${SHARED_DIR}
qemu-system-x86_64 \
  -nographic -serial mon:stdio \
	-kernel bzImage \
	-initrd rootfs.cpio.lz4 -m size=1024 \
	-append "nokaslr norandmaps console=ttyS0 console=tty root=/dev/ram0 crashkernel=256M" \
	-drive file=${ROOTFS_DISK},if=virtio \
	-virtfs local,path=${SHARED_DIR},mount_tag=host0,security_model=passthrough,id=host0 \
	-net nic,model=virtio \
	-net user
	# Compat: -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
