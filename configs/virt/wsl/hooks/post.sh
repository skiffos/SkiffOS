#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
HOST_DIR=${SKIFF_BUILDROOT_DIR}/host
PERSIST_DIR=${SKIFF_BUILDROOT_DIR}/extra_images/persist
BOOT_DIR=${PERSIST_DIR}/boot
ROOTFS_DIR=${PERSIST_DIR}/rootfs
SKIFF_IMAGE=${IMAGES_DIR}/skiffos.tar.gz
if [ -f ${SKIFF_IMAGE} ]; then
    rm -f ${SKIFF_IMAGE}
fi

echo "Building $(basename $SKIFF_IMAGE) for import to WSL..."

cd ${IMAGES_DIR}
mkdir -p ${PERSIST_DIR}/{bin,etc,root,sbin,tmp,boot}
mkdir -p ${BOOT_DIR}/skiff-init ${ROOTFS_DIR}/
if [ -d ${IMAGES_DIR}/rootfs_part/ ]; then
    rsync -rav ${IMAGES_DIR}/rootfs_part/ ${ROOTFS_DIR}/
fi
if [ -d ${IMAGES_DIR}/persist_part/ ]; then
    rsync -rav ${IMAGES_DIR}/persist_part/ ${PERSIST_DIR}/
fi
rsync -rv ./skiff-init/ ${BOOT_DIR}/skiff-init/
rsync -rv ./skiff-release ./rootfs.squashfs ${BOOT_DIR}/

# configure busybox
BUSYBOX_BINS=( blkid id whoami su dmesg mount sh unshare nsenter poweroff reboot )
cp ./skiff-init/busybox ${PERSIST_DIR}/bin/busybox
rm ${BOOT_DIR}/skiff-init/busybox || true
for b in ${BUSYBOX_BINS[@]}; do
    ln -fs ./busybox ${PERSIST_DIR}/bin/${b}
done

# wsl-shell
cp ./skiff-init/wsl-shell ${PERSIST_DIR}/bin/wsl-shell
rm ${BOOT_DIR}/skiff-init/wsl-shell || true

# create WSL configs
touch ${PERSIST_DIR}/etc/fstab
echo "root:x:0:root" > ${PERSIST_DIR}/etc/group
if [ -f ${PERSIST_DIR}/bin/wsl-shell ]; then
    echo "root:x:0:0:root:/root:/bin/wsl-shell" > ${PERSIST_DIR}/etc/passwd
else
    echo "root:x:0:0:root:/root:/bin/sh" > ${PERSIST_DIR}/etc/passwd
fi
cp ${SKIFF_CURRENT_CONF_DIR}/resources/wsl.conf ${PERSIST_DIR}/etc/wsl.conf

# WSL loads a .tar.gz
cd ${PERSIST_DIR}; find -print0 | LC_ALL=C sort -z | tar \
    --pax-option="exthdr.name=%d/PaxHeaders/%f,atime:=0,ctime:=0" \
    -cf ${SKIFF_IMAGE} --null --xattrs-include='*' \
    --no-recursion -T - --numeric-owner
echo "Created $(basename ${SKIFF_IMAGE}), import it with:"
echo "# wsl.exe --import SkiffOS C:\SkiffOS skiffos.tar.gz"
