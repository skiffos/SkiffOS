# note: persist and boot are mounted by skiff-init-squashfs.
export BOOT_DEVICE="/dev/mmcblk0p1"
export MOUNT_BOOT_DEVICE="true"
export PERSIST_DEVICE="/dev/mmcblk0p1"
export ROOTFS_DEVICE="/mnt/boot/rootfs"
export ROOTFS_MNT_FLAGS="--rbind"
