#!/bin/bash

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
boot_conf="${resources_path}/boot-scripts/boot.txt"
ubootimg="$BUILDROOT_DIR/output/images/u-boot-dtb.bin"
ubootscripts="${BUILDROOT_DIR}/output/images/hk_sd_fuse/"
sd_fuse_scr="${BUILDROOT_DIR}/output/images/hk_sd_fuse/sd_fusing.sh"
images_path="${BUILDROOT_DIR}/output/images"
MKEXT4="mkfs.ext4 -F -O ^64bit"

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' (usually dosfstools) and try again."
  exit 1
fi

if [ ! -f "$sd_fuse_scr" ]; then
  echo "Cannot find $sd_fuse_scr, make sure Buildroot is compiled."
  exit 1
fi

if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will completely destroy all data. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Verify that '$ODROID_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

set -x
set -e

echo "Formatting device..."
parted $ODROID_SD mklabel msdos

echo "Making boot partition..."
parted -a optimal $ODROID_SD mkpart primary fat32 2MiB 310MiB
parted $ODROID_SD set 1 boot on
parted $ODROID_SD set 1 lba on
sleep 1

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

mkfs.vfat -F 32 ${ODROID_SD_SFX}1
fatlabel ${ODROID_SD_SFX}1 bootmmc

echo "Making storage partition..."
parted -a optimal $ODROID_SD mkpart primary ext4 310MiB 100%
sleep 1
$MKEXT4 -L "storage" ${ODROID_SD_SFX}2

sync && sync
sleep 1

echo "Flashing u-boot..."
cd $ubootscripts
bash ./sd_fusing.sh $ODROID_SD $ubootimg
cd -

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
# deletes the temp directory
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

enable_silent() {
  if [ -f "$images_path/.disable-serial-console" ]; then
    echo "Disabling serial console and enabling silent mode..."
    sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
  fi
}

boot_dir="${WORK_DIR}/boot"
mkdir -p $boot_dir

echo "Mounting ${ODROID_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${ODROID_SD_SFX}1 $boot_dir

echo "Compiling boot.txt..."
cp $boot_conf $boot_dir/boot.txt
enable_silent $boot_dir/boot.txt
mkimage -A arm -C none -T script -n 'Skiff Odroid' -d $boot_dir/boot.txt $boot_dir/boot.scr
