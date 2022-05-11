#!/bin/bash
set -eo pipefail

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
# deletes the temp directory
function cleanup {
sync || true
for mount in "${mounts[@]}"; do
  echo "Unmounting ${mount}..."
  sudo umount $mount || true
done
mounts=()
if [ -d "$WORK_DIR" ]; then
  rm -rf "$WORK_DIR" || true
fi
}
trap cleanup EXIT

boot_dir="${WORK_DIR}/boot"
persist_dir="${WORK_DIR}/persist"

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

mkdir -p $boot_dir
echo "Mounting ${ODROID_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
sudo mount ${ODROID_SD_SFX}1 $boot_dir

# rootfs is a subdir of boot
rootfs_dir="${boot_dir}/rootfs"
mkdir -p ${rootfs_dir}

echo "Mounting ${ODROID_SD_SFX}2 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
sudo mount ${ODROID_SD_SFX}2 $persist_dir

echo "Copying kernel image..."
sync
rsync -rav --no-perms --no-owner --no-group $img_path $boot_dir/
sync

echo "Copying uInitrd..."
rsync -rav --no-perms --no-owner --no-group $uinit_path $boot_dir/rootfs.cpio.uboot
sync

if [ -d "$outp_path/images/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group $outp_path/images/persist_part/ $persist_dir/
  sync
fi

enable_silent() {
  if [ -f "$images_path/.disable-serial-console" ]; then
    echo "Disabling serial console and enabling silent mode..."
    sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
  fi
}

echo "Compiling boot.txt..."
cp $boot_conf $boot_dir/boot.txt
enable_silent $boot_dir/boot.txt
mkimage -A arm -C none -T script -n 'Skiff Odroid' -d $boot_dir/boot.txt $boot_dir/boot.scr
sync

echo "Copying device tree..."
rsync -rav --no-perms --no-owner --no-group ${images_path}/*.dtb $boot_dir/
sync

cleanup
