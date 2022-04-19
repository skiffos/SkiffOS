export QEMU_PERSIST_DEVICE="/dev/vda"
export PERSIST_DEVICE="${QEMU_PERSIST_DEVICE}1"
if [ ! -b ${QEMU_PERSIST_DEVICE} ]; then
    echo "${QEMU_PERSIST_DEVICE} not found: expected persist device"
elif [ ! -b ${PERSIST_DEVICE} ]; then
    echo "${PERSIST_DEVICE} not found: creating partition layout"
    parted ${QEMU_PERSIST_DEVICE} mklabel msdos
    partprobe ${QEMU_PERSIST_DEVICE} || true
    parted -a optimal ${QEMU_PERSIST_DEVICE} -- mkpart primary ext4 2MiB "100%"
    partprobe ${QEMU_PERSIST_DEVICE} || true
    mkfs.ext4 -F -L "persist" ${PERSIST_DEVICE}
fi

export DISABLE_RESIZE_PERSIST="true"
export ROOTFS_DEVICE="/mnt/persist/rootfs"
export ROOTFS_MNT_FLAGS="--rbind"
export BOOT_DEVICE="/mnt/persist/boot"
export BOOT_MNT_FLAGS="--rbind"
