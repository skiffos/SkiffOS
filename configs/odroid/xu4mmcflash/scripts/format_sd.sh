#!/bin/bash
set -eo pipefail

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/output/images/u-boot.bin"
ubootimgb="$BUILDROOT_DIR/output/images/u-boot-dtb.bin"

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

if [ -z "$ODROID_SD" ]; then
  echo "Please set ODROID_SD and try again."
  exit 1
fi

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgb
fi

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg or $ubootimgb"
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

echo "Flashing stager u-boot..."
cat ${resources_path}/boot.bin.gz | gzip -d | dd of=$ODROID_SD
sync && sync

printf "Waiting for the OS to recognize the new partitions"
if ! partprobe $ODROID_SD ; then
  echo "\nnote: your system does not have partprobe, this might time out"
fi
for ((i=0; i<20; i++)); do
  printf "."
  if [ -b ${ODROID_SD}1 ] || [ -b ${ODROID_SD}p1 ]; then
    break
  fi
  sleep 1
done
printf "\n"
if ((i==20)); then
  echo "OS did not recognize the new partition, failing."
  exit 1
fi

ODROID_SD_SFX=$ODROID_SD
if [ -b ${ODROID_SD}p1 ]; then
  ODROID_SD_SFX=${ODROID_SD}p
fi

echo "Wiping boot partition..."
mkfs.vfat -F 32 ${ODROID_SD_SFX}1
fatlabel ${ODROID_SD_SFX}1 BOOT

sync && sync

echo "Mounting boot partition..."
boot_dir="${WORK_DIR}/boot"

mkdir -p $boot_dir
echo "Mounting ${ODROID_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${ODROID_SD_SFX}1 $boot_dir

echo "Copying in flasher config..."
rsync -rv $resources_path/flasher/ $boot_dir/
echo "Copying in u-boot image..."
cp $ubootimg $boot_dir/u-boot.bin

sync
