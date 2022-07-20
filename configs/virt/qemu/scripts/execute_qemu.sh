#!/bin/bash
set -eo pipefail

IMAGES_DIR=$BUILDROOT_DIR/images
QEMU_DIR=${BUILDROOT_DIR}/qemu-exec
ROOTFS_IMAGE=${QEMU_DIR}/qemu-image.img
ROOTFS_DISK=${QEMU_DIR}/qemu-persist.qcow2
SHARED_DIR=${QEMU_DIR}/qemu-shared
GENIMAGE_CFG=${SKIFF_CURRENT_CONF_DIR}/resources/qemu-genimage.cfg
GENIMAGE_TMP=${QEMU_DIR}/genimage.tmp

# Sparse rootfs file
# however: embiggen-disk can be quite slow
if [ -z "${ROOTFS_MAX_SIZE}" ]; then
  ROOTFS_MAX_SIZE="32G"
fi

mkdir -p ${QEMU_DIR}
cd ${IMAGES_DIR}
if [ ! -f ${ROOTFS_IMAGE} ]; then
	  echo "Building qemu root image..."
	  mkdir -p ${QEMU_DIR}/fakeroot
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
    qemu-img create -f qcow2 ${ROOTFS_DISK} ${ROOTFS_MAX_SIZE}

    # Convert existing image to sparse image & resize
    # qemu-img convert -f raw -O qcow2 ${ROOTFS_IMAGE} ${ROOTFS_DISK}
    # qemu-img resize ${ROOTFS_DISK} ${ROOTFS_MAX_SIZE}
fi

KERNEL_IMAGE=Image
if [ ! -f ${KERNEL_IMAGE} ]; then
    KERNEL_IMAGE=zImage
fi
if [ ! -f ${KERNEL_IMAGE} ]; then
    KERNEL_IMAGE=bzImage
fi
if [ ! -f ${KERNEL_IMAGE} ]; then
    echo "kernel image not found, is the system compiled?"
    exit 1
fi

if [ -z "${QEMU_CPUS}" ]; then
    QEMU_CPUS="$(nproc)"
fi

if [ -z "${QEMU_MEMORY}" ]; then
    QEMU_MEMORY="2G"
fi

# run the target architecture qemu-system
# Compat: -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
# Host: -cpu host
# Faster networking, but needs root: -nic tap
mkdir -p ${SHARED_DIR}
${BUILDROOT_DIR}/host/bin/qemu-system \
  -bios default \
  -machine virt \
  -netdev user,id=vmnic \
  -smp ${QEMU_CPUS} \
  -m "size=${QEMU_MEMORY}" \
  -device virtio-net,netdev=vmnic \
  -device virtio-rng-pci \
  -nographic -serial mon:stdio \
	-kernel ${KERNEL_IMAGE} \
	-initrd rootfs.cpio.lz4 \
	-append "console=ttyS0 console=tty root=/dev/ram0 crashkernel=256M" \
	-drive file=${ROOTFS_DISK},if=virtio \
	-virtfs local,path=${SHARED_DIR},mount_tag=host0,security_model=mapped,id=host0
