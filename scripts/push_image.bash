#!/bin/bash
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
ssh $SSHSTR 'bash -s' <<EOF
set -eo pipefail
sync
if ! mountpoint -q /mnt/boot ; then
  mkdir -p /mnt/boot
  if [ -b /dev/mmcblk0p1 ]; then
    mount /dev/mmcblk0p1 /mnt/boot
  elif [ -b /dev/mmcblk1p1 ]; then
    mount /dev/mmcblk1p1 /mnt/boot
  else
    mount LABEL="BOOT" /mnt/boot
  fi
fi
sync
mount -o remount,rw /mnt/rootfs
EOF
if [ -f ${WS}/rootfs.cpio.uboot ]; then
    $RS ${WS}/rootfs.cpio.uboot $SSHSTR:/mnt/boot/rootfs.cpio.uboot
else
    $RS ${WS}/rootfs.cpio.gz $SSHSTR:/mnt/boot/rootfs.cpio.gz
fi
if [ -d ${WS}/rootfs_part ]; then
    $RS ${WS}/rootfs_part/ $SSHSTR:/mnt/rootfs/
fi
if [ -f ${WS}/zImage ]; then
  $RS ${WS}/zImage $SSHSTR:/mnt/boot/zImage
else
  $RS ${WS}/Image $SSHSTR:/mnt/boot/Image
fi
$RS ${WS}/*.dtb $SSHSTR:/mnt/boot/
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

