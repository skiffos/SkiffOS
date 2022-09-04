#!/bin/bash
set -eo pipefail

# Loads config
if [ -z "$SKIFF_CURRENT_CONF_DIR" ]; then
    echo "SKIFF_CURRENT_CONF_DIR must be set: install_to_dir.bash"
    exit 1
fi

# Installs to PERSIST_DIR.
if [ -z "$PERSIST_DIR" ]; then
    echo "PERSIST_DIR must be set: install_to_dir.bash"
    exit 1
fi

if [ ! -d ./skiff-init ]; then
    echo "Run install_to_dir.bash from the images dir."
    exit 1
fi

BOOT_DIR=${PERSIST_DIR}/boot
ROOTFS_DIR=${PERSIST_DIR}/rootfs

# copy the extlinux conf
mkdir -p ${BOOT_DIR}/extlinux
cp ${SKIFF_CURRENT_CONF_DIR}/resources/boot-scripts/extlinux.conf ${BOOT_DIR}/extlinux/extlinux.conf

# copy dtbs
rsync --delete -rv ./dtb/ ${BOOT_DIR}/dtb/

# skiff-init
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
rsync -rv ./skiff-init/ ${BOOT_DIR}/skiff-init/
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ${BOOT_DIR}/skiff-init/resize2fs.conf

# rootfs_part
if [ -d ./rootfs_part/ ]; then
    rsync -rav ./rootfs_part/ ${ROOTFS_DIR}/
fi

# persist_part
if [ -d ./persist_part/ ]; then
    rsync -rav ./persist_part/ ${PERSIST_DIR}/
fi

# copy image and rootfs
rsync -rv ./Image ./skiff-release ./rootfs.squashfs ${BOOT_DIR}/
