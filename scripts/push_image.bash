#!/bin/bash
shopt -s nullglob
set -eo pipefail

CMD=$0

usage() {
    echo "usage: $CMD root@192.168.1.41"
}

SSHSTR=$1
RS="rsync -rv --progress"

if [ -z "$SSHSTR" ]; then
    usage
    exit 1
fi

SKIFF_WORKSPACE=${SKIFF_WORKSPACE:-default}
if [ ! -d ./workspaces ]; then
    usage
    echo "please run from the root dir: ./scripts/push_image.sh"
    exit 1
fi
WS="./workspaces/${SKIFF_WORKSPACE}/images"
if [ ! -d $WS ]; then
    echo "Could not find: $WS"
    exit 1
fi

echo "Ensuring mountpoints..."
ssh $SSHSTR 'bash -s' <<'EOF'
set -xeo pipefail
sync
if ! mountpoint -q /mnt/boot ; then
  for f in /opt/skiff/scripts/mount-all.pre.d/*.sh; do
    source $f || true
  done
  mkdir -p /mnt/boot
  if [ -n "$BOOT_DEVICE" ]; then
    mount $BOOT_DEVICE $BOOT_MNT_FLAGS /mnt/boot
  elif [ -b /dev/disk/by-label/BOOT ]; then
    mount LABEL="BOOT" /mnt/boot
  elif [ -b /dev/disk/by-label/boot ]; then
    mount LABEL="boot" /mnt/boot
  elif [ -b /dev/mmcblk0p1 ]; then
    mount /dev/mmcblk0p1 /mnt/boot
  elif [ -b /dev/mmcblk1p1 ]; then
    mount /dev/mmcblk1p1 /mnt/boot
  else
    echo "Unable to determine boot device."
    exit 1
  fi
fi
sync
if [ -n "$ROOTFS_REMOUNT_RW" ] || ! [ -w /mnt/rootfs ]; then
  mount -o remount,rw /mnt/rootfs
fi
EOF
if [ -f ${WS}/rootfs.cpio.uboot ]; then
    $RS ${WS}/rootfs.cpio.uboot $SSHSTR:/mnt/boot/rootfs.cpio.uboot
elif [ -f ${WS}/rootfs.squashfs ]; then
    $RS ${WS}/rootfs.squashfs $SSHSTR:/mnt/boot/rootfs.squashfs
elif [ -f ${WS}/rootfs.cpio.lz4 ]; then
    $RS ${WS}/rootfs.cpio.lz4 $SSHSTR:/mnt/boot/rootfs.cpio.lz4
elif [ -f ${WS}/rootfs.cpio.gz ]; then
    $RS ${WS}/rootfs.cpio.gz $SSHSTR:/mnt/boot/rootfs.cpio.gz
fi
if [ -d ${WS}/rootfs_part ]; then
    $RS ${WS}/rootfs_part/ $SSHSTR:/mnt/rootfs/
fi

IMG_TYPES=( zImage Image bzImage vmlinux )
for t in ${IMG_TYPES[@]}; do
    if [ -f ${WS}/$t ]; then
        $RS ${WS}/$t $SSHSTR:/mnt/boot/
        break
    fi
done

DTB_FILES=( ${WS}/*.dtb )
if (( ${#DTB_FILES[@]} )); then
    $RS ${WS}/*.dtb $SSHSTR:/mnt/boot/
fi
if [ -f ${WS}/skiff-release ]; then
  $RS ${WS}/skiff-release $SSHSTR:/mnt/boot/skiff-release
fi
if [ -d ${WS}/rpi-firmware ]; then
    $RS ${WS}/rpi-firmware/overlays/ $SSHSTR:/mnt/boot/overlays/
    $RS ${WS}/rpi-firmware/*.bin \
        ${WS}/rpi-firmware/*.dat \
        ${WS}/rpi-firmware/*.elf \
        $SSHSTR:/mnt/boot/
fi
ssh $SSHSTR 'bash -s' <<EOF
sync && sync
EOF

echo "Done."


