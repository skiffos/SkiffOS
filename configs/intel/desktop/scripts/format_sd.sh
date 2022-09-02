#!/bin/bash

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! command -v parted >/dev/null 2>&1; then
  echo "Please install 'parted' and try again if this script fails."
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' and try again if this script fails."
fi

outp_path="${BUILDROOT_DIR}/output"
boot_path="${outp_path}/images/refind"

if [ ! -d "$boot_path" ]; then
    echo "refind not found, make sure Buildroot is done compiling."
    exit 1
fi

if [ -z "$INTEL_DESKTOP_DISK" ]; then
  echo "Please set INTEL_DESKTOP_DISK and try again."
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
  read -p "Verify that '$INTEL_DESKTOP_DISK' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

set -x
set -e

echo "Formatting device..."
sudo parted $INTEL_DESKTOP_DISK mklabel gpt
sleep 1

echo "Making boot partition..."
sudo parted -a optimal $INTEL_DESKTOP_DISK mkpart primary fat16 2048s 128MB
sudo parted $INTEL_DESKTOP_DISK set 1 boot on
sudo parted $INTEL_DESKTOP_DISK set 1 esp on

echo "Making persist partition..."
sudo parted -a optimal $INTEL_DESKTOP_DISK -- mkpart primary ext4 128MB "100%"

echo "Waiting for partprobe..."
sudo partprobe $INTEL_DESKTOP_DISK || true
sleep 2

INTEL_DESKTOP_DISK_SFX=$INTEL_DESKTOP_DISK
if [ -b ${INTEL_DESKTOP_DISK}p1 ]; then
    INTEL_DESKTOP_DISK_SFX=${INTEL_DESKTOP_DISK}p
fi

echo "Formatting EFI partition..."
mkfs.vfat -n EFI -F 16 ${INTEL_DESKTOP_DISK_SFX}1

echo "Formatting SKIFFOS partition..."
mkfs.ext4 -F -L "SKIFFOS" ${INTEL_DESKTOP_DISK_SFX}2

sudo partprobe $INTEL_DESKTOP_DISK || true

# Install rEFind to the first partition.
mounts=()
MOUNTS_DIR=${outp_path}/mounts
mkdir -p ${MOUNTS_DIR}
WORK_DIR=`mktemp -d -p "${MOUNTS_DIR}"`
RS="rsync -rav --no-perms --no-owner --no-group --progress --inplace"

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

efi_dir="${WORK_DIR}/efi"

echo "Mounting ${INTEL_DESKTOP_DISK_SFX}1 to $efi_dir..."
mkdir -p $efi_dir
mounts+=("$efi_dir")
mount ${INTEL_DESKTOP_DISK_SFX}1 $efi_dir

echo "Copying rEFInd..."
${RS} ${boot_path}/ ${efi_dir}/

sync
cleanup
