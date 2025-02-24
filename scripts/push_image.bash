#!/usr/bin/env bash
# SkiffOS OTA Update Script
# Pushes compiled images to remote device over SSH
shopt -s nullglob
set -eo pipefail

CMD="$0"

# Display usage information
function usage() {
  echo "Usage: $CMD root@192.168.1.41"
}

# Parse command line arguments
SSHSTR="$1"
RS="rsync -rv --progress --sparse"

# Validate input
if [[ -z "$SSHSTR" ]]; then
  usage
  exit 1
fi

# Set up workspace paths
SKIFF_ROOT="${SKIFF_ROOT:-.}"
SKIFF_WORKSPACE="${SKIFF_WORKSPACE:-default}"

# Verify we're in the right directory
if [[ ! -d "${SKIFF_ROOT}/workspaces" ]]; then
  usage
  echo "Please run from the root dir ${SKIFF_ROOT} - ./scripts/push_image.bash"
  exit 1
fi

# Check if workspace exists
WS="${SKIFF_ROOT}/workspaces/${SKIFF_WORKSPACE}/images"
if [[ ! -d "$WS" ]]; then
  echo "Could not find workspace: $WS"
  exit 1
fi

# Check if this is an Intel desktop system
if [[ -d "${WS}/efi-part/EFI/refind" ]] && [[ -d "${WS}/intel" ]]; then
  echo "Detected intel/desktop system, using push_intel_desktop.bash instead..."
  exec "${SKIFF_ROOT}/scripts/push_intel_desktop.bash" "${@}"
fi

echo "Ensuring mountpoints on remote device..."
ssh "$SSHSTR" 'bash -s' <<'EOF'
set -xeo pipefail
sync

# Mount boot partition if not already mounted
if ! mountpoint -q /mnt/boot ; then
  # Run any pre-mount scripts
  for f in /opt/skiff/scripts/mount-all.pre.d/*.sh; do
    source "$f" || true
  done
  
  # Create mount point
  mkdir -p /mnt/boot
  
  # Try to find and mount boot device
  if [[ -n "$BOOT_DEVICE" ]]; then
    mount "$BOOT_DEVICE" $BOOT_MNT_FLAGS /mnt/boot
  elif [[ -b /dev/disk/by-label/BOOT ]]; then
    mount LABEL="BOOT" /mnt/boot
  elif [[ -b /dev/disk/by-label/boot ]]; then
    mount LABEL="boot" /mnt/boot
  elif [[ -b /dev/mmcblk0p1 ]]; then
    mount /dev/mmcblk0p1 /mnt/boot
  elif [[ -b /dev/mmcblk1p1 ]]; then
    mount /dev/mmcblk1p1 /mnt/boot
  else
    echo "Unable to determine boot device."
    exit 1
  fi
fi

# Ensure rootfs is writable
sync
if [[ -n "$ROOTFS_REMOUNT_RW" ]] || ! [[ -w /mnt/rootfs ]]; then
  mount -o remount,rw /mnt/rootfs
fi
EOF

# Push rootfs image
if [[ -f "${WS}/rootfs.cpio.uboot" ]]; then
  $RS "${WS}/rootfs.cpio.uboot" "$SSHSTR:/mnt/boot/rootfs.cpio.uboot"
elif [[ -f "${WS}/rootfs.squashfs" ]]; then
  $RS "${WS}/rootfs.squashfs" "$SSHSTR:/mnt/boot/rootfs.squashfs"
elif [[ -f "${WS}/rootfs.cpio.lz4" ]]; then
  $RS "${WS}/rootfs.cpio.lz4" "$SSHSTR:/mnt/boot/rootfs.cpio.lz4"
elif [[ -f "${WS}/rootfs.cpio.gz" ]]; then
  $RS "${WS}/rootfs.cpio.gz" "$SSHSTR:/mnt/boot/rootfs.cpio.gz"
fi

# Push boot partition
if [[ -d "${WS}/boot_part" ]]; then
  $RS "${WS}/boot_part/" "$SSHSTR:/mnt/boot/"
fi

# Push rootfs partition
if [[ -d "${WS}/rootfs_part" ]]; then
  $RS "${WS}/rootfs_part/" "$SSHSTR:/mnt/rootfs/"
fi

# Push skiff-init
if [[ -d "${WS}/skiff-init" ]]; then
  $RS "${WS}/skiff-init/" "$SSHSTR:/mnt/boot/skiff-init/"
fi
if [[ -f "${WS}/skiff-init.img" ]]; then
  $RS "${WS}/skiff-init.img" "$SSHSTR:/mnt/boot/skiff-init.img"
fi

# Push kernel image (try different formats)
IMG_TYPES=("zImage" "Image" "bzImage" "vmlinux")
for img_type in "${IMG_TYPES[@]}"; do
  if [[ -f "${WS}/${img_type}" ]]; then
    $RS "${WS}/${img_type}" "$SSHSTR:/mnt/boot/"
    break
  fi
done

# Push device tree blobs
DTB_FILES=("${WS}"/*.dtb{,o})
if (( ${#DTB_FILES[@]} )); then
  $RS "${DTB_FILES[@]}" "$SSHSTR:/mnt/boot/"
fi

# Push release info
if [[ -f "${WS}/skiff-release" ]]; then
  $RS "${WS}/skiff-release" "$SSHSTR:/mnt/boot/skiff-release"
fi

# Handle Raspberry Pi firmware
if [[ -d "${WS}/rpi-firmware" ]]; then
  # Push overlays
  $RS --delete \
      "${WS}/rpi-firmware/overlays/" \
      "$SSHSTR:/mnt/boot/overlays/"
  
  # Push firmware files
  $RS --delete \
      "${WS}/rpi-firmware/"*.{bin,dat,elf} \
      "$SSHSTR:/mnt/boot/"

  # Upgrade Pi to LZ4 CPIO if available
  if [[ -f "${WS}/rootfs.cpio.lz4" ]]; then
    ssh "$SSHSTR" 'bash -s' <<EOF
# Update config.txt to use lz4 and remove old gz file if present
sed -i -e "s/^initramfs .*/initramfs rootfs.cpio.lz4/" /mnt/boot/config.txt
if [[ -f /mnt/boot/rootfs.cpio.gz ]] && [[ -f /mnt/boot/rootfs.cpio.lz4 ]]; then
  rm /mnt/boot/rootfs.cpio.gz
fi
EOF
  fi
fi

# Sync filesystems
ssh "$SSHSTR" 'bash -s' <<EOF
sync && sync
EOF

echo "Done."