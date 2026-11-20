#!/bin/bash
# Installs SkiffOS onto an SD card that format_sd.sh prepared.
#
# Partition 1 (FAT) holds what U-Boot and skiff-init read: extlinux.conf, the
# kernel, the device tree, rootfs.squashfs and skiff-init. Partition 2 (ext4)
# holds persist, with the module image under persist/rootfs. U-Boot's standard
# boot finds /extlinux/extlinux.conf on partition 1 with no boot script.
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$PINE64_SD" ]; then
  echo "Please set PINE64_SD and try again."
  exit 1
fi

if [ ! -b "$PINE64_SD" ]; then
  echo "$PINE64_SD is not a block device or doesn't exist."
  exit 1
fi

PINE64_SD_SFX=$PINE64_SD
if [ -b ${PINE64_SD}p1 ]; then
  PINE64_SD_SFX=${PINE64_SD}p
fi

images_path="${BUILDROOT_DIR}/images"
resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
for f in zImage sun8i-s3-pinecube.dtb rootfs.squashfs skiff-init; do
  if [ ! -e "${images_path}/${f}" ]; then
    echo "${images_path}/${f} not found, make sure Buildroot is done compiling."
    exit 1
  fi
done

mounts=()
MOUNTS_DIR=${BUILDROOT_DIR}/mounts
mkdir -p ${MOUNTS_DIR}
WORK_DIR=$(mktemp -d -p "${MOUNTS_DIR}")
RS="rsync -rav --no-perms --no-owner --no-group --progress --inplace"

function cleanup {
  sync || true
  for mount in "${mounts[@]}"; do
    echo "Unmounting ${mount}..."
    umount $mount || true
  done
  mounts=()
  if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR" || true
  fi
}
trap cleanup EXIT

boot_dir="${WORK_DIR}/boot"
persist_dir="${WORK_DIR}/persist"
rootfs_dir="${persist_dir}/rootfs"
mkdir -p $boot_dir $persist_dir

# A desktop may have mounted the card on insert, and checking a mounted
# filesystem corrupts it.
if command -v findmnt >/dev/null 2>&1 && findmnt -rn -S ${PINE64_SD_SFX}1 >/dev/null 2>&1; then
  echo "${PINE64_SD_SFX}1 is mounted elsewhere, unmounting before the check..."
  umount ${PINE64_SD_SFX}1
fi

# rsync --inplace onto FAT after an unclean unmount leaves orphaned cluster
# chains that silently fill the partition, so check it on every install.
# fsck.vfat exits 0 when clean and 1 when repaired; anything higher means the
# filesystem could not be verified.
if command -v fsck.vfat >/dev/null 2>&1; then
  fsck_rc=0
  fsck.vfat -a ${PINE64_SD_SFX}1 || fsck_rc=$?
  if [ "$fsck_rc" -gt 1 ]; then
    echo "fsck.vfat returned ${fsck_rc} on ${PINE64_SD_SFX}1, refusing to continue." >&2
    exit 1
  fi
else
  echo "WARNING: fsck.vfat not found (install dosfstools), skipping the boot partition check."
fi

echo "Mounting ${PINE64_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${PINE64_SD_SFX}1 $boot_dir
# fsck.vfat -a saves orphaned chains as FSCK*.REC; here they are always
# leftovers of an earlier install.
rm -f "$boot_dir"/FSCK*.REC

echo "Mounting ${PINE64_SD_SFX}2 to $persist_dir..."
mounts+=("$persist_dir")
mount ${PINE64_SD_SFX}2 $persist_dir

echo "Copying kernel, device tree, rootfs and skiff-init..."
${RS} ${images_path}/zImage ${images_path}/sun8i-s3-pinecube.dtb $boot_dir/
${RS} ${images_path}/rootfs.squashfs $boot_dir/rootfs.squashfs
${RS} ${images_path}/skiff-init/ $boot_dir/skiff-init/
mkdir -p $boot_dir/extlinux
cp ${resources_path}/extlinux.conf $boot_dir/extlinux/extlinux.conf
sync

if [ -d "${images_path}/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  mkdir -p ${rootfs_dir}
  ${RS} ${images_path}/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "${images_path}/persist_part" ]; then
  echo "Copying persist_part..."
  ${RS} ${images_path}/persist_part/ $persist_dir/
  sync
fi

# The PineCube has 128 MB of RAM, so swap on persist matters more than on
# most boards.
if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
  PERSIST_SWAP=${persist_dir}/primary.swap
  if [ ! -f ${PERSIST_SWAP} ]; then
    echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
    dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
  fi
fi
