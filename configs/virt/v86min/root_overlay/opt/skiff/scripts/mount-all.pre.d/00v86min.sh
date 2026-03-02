# v86min: ramdisk-only, no persist partition or block devices.
export SKIP_MOUNT_FLAG=/etc/skip-skiff-mounts
touch $SKIP_MOUNT_FLAG
export DISABLE_RESIZE_PERSIST=true
export DISABLE_ROOT_REMOUNT_RW=true
