# m1 uses a different partition layout
export BOOT_DEVICE="LABEL=boot"
export MOUNT_BOOT_DEVICE="true"
export ROOTFS_DEVICE="/mnt/boot/rootfs"
export ROOTFS_MNT_FLAGS="--rbind"
export PERSIST_DEVICE="LABEL=persist"
