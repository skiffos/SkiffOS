#!/bin/bash
set -eo pipefail

IMAGES_DIR=$BUILDROOT_DIR/images
QEMU_DIR=${BUILDROOT_DIR}/qemu-exec
ROOTFS_DISK=${QEMU_DIR}/qemu-persist.qcow2
SHARED_DIR=${QEMU_DIR}/qemu-shared

# sparse rootfs file
if [ -z "${ROOTFS_MAX_SIZE}" ]; then
  ROOTFS_MAX_SIZE="32G"
fi

mkdir -p ${QEMU_DIR}
cd ${IMAGES_DIR}
if [ ! -f ${ROOTFS_DISK} ]; then
    # Sparse/dynamically allocated image
    qemu-img create -f qcow2 ${ROOTFS_DISK} ${ROOTFS_MAX_SIZE}
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
  -smp ${QEMU_CPUS} \
  -m "size=${QEMU_MEMORY}" \
  -nographic -serial mon:stdio \
  -device virtio-rng-pci \
  -device virtio-net,netdev=vmnic \
  -netdev user,id=vmnic \
  -kernel ${KERNEL_IMAGE} \
  -initrd rootfs.cpio.lz4 \
  -append "console=ttyS0 root=/dev/ram0" \
  -drive file=${ROOTFS_DISK},if=virtio \
  -virtfs local,path=${SHARED_DIR},mount_tag=host0,security_model=mapped,id=host0
