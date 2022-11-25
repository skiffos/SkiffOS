# /mnt/boot is mounted by skiff-init-squashfs
export ROOTFS_DEVICE="/mnt/boot"
export ROOTFS_MNT_FLAGS="--rbind"
# use the 52Gb userdata partition for persist
export PERSIST_DEVICE="/dev/sda8"
export DISABLE_RESIZE_PERSIST="true"
