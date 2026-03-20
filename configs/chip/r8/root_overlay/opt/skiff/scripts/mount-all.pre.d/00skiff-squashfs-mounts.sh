# CHIP NAND boot: persist is UBI volume 1 (ubi0:persist), formatted as UBIFS.
# UBI is attached by the kernel via ubi.mtd=2 at boot.
export PERSIST_DEVICE="/dev/ubi0_1"
export PERSIST_MNT_FLAGS="-t ubifs"
export DISABLE_RESIZE_PERSIST="true"

# No separate rootfs or boot partition on NAND layout.
unset ROOTFS_DEVICE
unset BOOT_DEVICE
