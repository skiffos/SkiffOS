#!/bin/bash
set -eo pipefail

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
  exit 1
fi

if [ ! -b "$PI_SD" ]; then
  echo "$PI_SD is not a block device or doesn't exist."
  exit 1
fi

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
    PI_SD_SFX=${PI_SD}p
fi

outp_path="${BUILDROOT_DIR}"
images_path="${outp_path}/images"
uimg_path="${images_path}/zImage"
squashfs_path="${images_path}/rootfs.squashfs"
skiff_init_path="${images_path}/skiff-init/"
firm_path="${images_path}/rpi-firmware"

if [ ! -f "$uimg_path" ]; then
  uimg_path="${images_path}/Image"
fi

if [ ! -f "$uimg_path" ]; then
  echo "zImage or Image not found, make sure Buildroot is done compiling."
  exit 1
fi

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh

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

boot_dir="${WORK_DIR}/boot"
persist_dir="${WORK_DIR}/persist"
rootfs_dir="${persist_dir}/rootfs"

mkdir -p $boot_dir

# Desktop environments mount removable media on insert, and fsck on a
# mounted filesystem corrupts it — "-a" answers its own "really check it?"
# prompt with yes, so the usual safety net does not apply here.
if command -v findmnt >/dev/null 2>&1 && findmnt -rn -S ${PI_SD_SFX}1 >/dev/null 2>&1; then
  echo "${PI_SD_SFX}1 is already mounted elsewhere, unmounting before the check..."
  umount ${PI_SD_SFX}1
fi

# In-place rsync writes onto the FAT32 boot partition (rootfs.squashfs
# overwritten in place, see below) leave orphaned cluster chains behind if
# a previous update was interrupted before a clean unmount (dirty bit set).
# Those chains stay allocated but invisible to ls/du, silently eating the
# ~1GB partition until "No space left on device" — verified: 4 unclean
# cycles reserved ~660MB of ghost usage on a BPI-M2-Ultra. Run fsck -a
# every time so this self-heals instead of accumulating.
if ! command -v fsck.vfat >/dev/null 2>&1; then
  echo "WARNING: fsck.vfat not found (install dosfstools) — skipping the boot"
  echo "         partition check. Orphaned clusters will accumulate silently."
else
  echo "Checking ${PI_SD_SFX}1 for orphaned clusters before mounting..."
  # Exit codes: 0 = clean, 1 = repaired. Both are expected here, so they must
  # not abort the run under "set -e". Anything above 1 means the filesystem
  # could not be verified — writing onto it anyway is how the ghost usage got
  # missed in the first place, so stop instead.
  fsck_rc=0
  fsck.vfat -a ${PI_SD_SFX}1 || fsck_rc=$?
  if [ "$fsck_rc" -gt 1 ]; then
    echo "fsck.vfat returned ${fsck_rc} on ${PI_SD_SFX}1 — refusing to continue." >&2
    exit 1
  fi
fi
echo "Mounting ${PI_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${PI_SD_SFX}1 $boot_dir
# fsck -a recovers orphaned chains as FSCK####.REC files instead of freeing
# them outright — on this partition they're always leftovers from a prior
# update (nothing here legitimately creates such files), safe to delete.
rm -f "$boot_dir"/FSCK*.REC

echo "Mounting ${PI_SD_SFX}2 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${PI_SD_SFX}2 $persist_dir

echo "Copying kernel..."
${RS} $uimg_path $boot_dir/
sync

if [ -d "$outp_path/images/boot_part" ]; then
    echo "Copying boot_part..."
    ${RS} $outp_path/images/boot_part/ $boot_dir/
    sync
fi

if [ -d "$outp_path/images/rootfs_part" ]; then
    echo "Copying rootfs_part..."
    mkdir -p ${rootfs_dir}
    ${RS} $outp_path/images/rootfs_part/ $rootfs_dir/
    sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
    echo "Copying persist_part..."
    ${RS} $outp_path/images/persist_part/ $persist_dir/
    sync
fi

if [ -f $squashfs_path ]; then
    echo "Copying rootfs.squashfs..."
    ${RS} $squashfs_path $boot_dir/rootfs.squashfs
    sync
fi

if [ -d $skiff_init_path ]; then
    echo "Copying skiff-init..."
    ${RS} $skiff_init_path $boot_dir/skiff-init/
    sync
fi

if [ -z "$DISABLE_CREATE_SWAPFILE" ]; then
    PERSIST_SWAP=${persist_dir}/primary.swap
    if [ ! -f ${PERSIST_SWAP} ]; then
        echo "Pre-allocating 2GB swapfile with zeros (ignoring errors)..."
        dd if=/dev/zero of=${PERSIST_SWAP} bs=1M count=2000 || true
    fi
fi

enable_silent() {
  if [ -f "$images_path/.disable-serial-console" ]; then
    echo "Disabling serial console and enabling silent mode..."
    sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
  fi
}

if [ -n "$boot_conf_enc" ]; then
  echo "Compiling boot.txt..."
  cp $boot_conf $boot_dir/boot.txt
  enable_silent $boot_dir/boot.txt
  mkimage -A arm -C none -T script -d $boot_dir/boot.txt $boot_dir/boot.scr
else
  echo "Copying boot.ini..."
  cp $boot_conf $boot_dir/boot.ini
  enable_silent $boot_dir/boot.ini
fi

echo "Copying device tree(s)..."
${RS} ${images_path}/*.dtb $boot_dir/
sync
