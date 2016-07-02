#!/bin/bash
set -e

MOUNTPOINT=/mnt/persist
MARKER=$MOUNTPOINT/.resized

if [ -f $MARKER ]; then
  echo "Marker $MARKER in place, skipping."
  exit 0
fi

DEVPATH=$(df | grep "${MOUNTPOINT}\$" | head -n1 | awk '{print $1}')
if [ -z "$DEVPATH" ]; then
  echo "Dev path cannot be found for ${MOUNTPOINT}."
  exit 1
fi

echo "Disk partition detected at ${MOUNTPOINT} -> ${DEVPATH}"
disk=$(lsblk -no pkname $DEVPATH)
echo "Disk detected at ${disk}."
part_num=$(lsblk -f $DEVPATH -o "MAJ:MIN" | tail -n1 | cut -d: -f2)
echo "Partition number detected as $part_num"
disk_part=$DEVPATH
p2_start=$(fdisk -l /dev/mmcblk0 | grep $disk_part | awk '{print $2}')
echo "Partition start: $p2_start"
p2_end=$(fdisk -l /dev/mmcblk0 | grep $disk_part | awk '{print $3}')
echo "Partition end: $p2_end"

disk_size=$(blockdev --getsize /dev/$disk)
echo "Disk size: $disk_size"

if [ ! $(($disk_size-$p2_end)) -le 10485760 ]; then
  echo "No need to resize, exiting."
  exit 0
fi

p2_new_end=$((disk_size-10))

echo "Resizing $disk_part from $p2_end to $p2_new_end"

fdisk /dev/mmcblk0 <<EOF
p
d
$part_num
n
p
$part_num
$p2_start
$p2_new_end
p
w
EOF

resize2fs ${disk_part}
touch $MARKER
echo "Resized rootfs, rebooting"
reboot
