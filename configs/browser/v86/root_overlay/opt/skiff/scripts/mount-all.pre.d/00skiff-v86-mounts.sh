export BOOT_DEVICE="/boot"
export BOOT_MNT_FLAGS="--rbind"
export MOUNT_BOOT_DEVICE="true"
export ROOTFS_DEVICE="/boot"
export ROOTFS_MNT_FLAGS="--rbind"
export PERSIST_DEVICE="/persist"
export PERSIST_MNT_FLAGS="--rbind"
export DISABLE_RESIZE_PERSIST="true"

# To use the 9p filesystem instead:
# export PERSIST_DEVICE="host9p"
# export PERSIST_MNT_FLAGS="-o trans=virtio,rw,cache=fscache -t 9p"
