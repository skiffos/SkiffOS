#!/bin/bash
set -eo pipefail

MOUNTPOINT=/mnt/persist
MARKER=$MOUNTPOINT/.resized

if ! mountpoint $MOUNTPOINT ; then
  echo "$MOUNTPOINT is not a mountpoint!"
  exit 1
fi

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
part_num=$(lsblk -f $DEVPATH -o "MAJ:MIN" | tail -n1 | cut -d: -f2 | tr -d '[[:space:]]')
echo "Partition number detected as $part_num"
disk_part=$DEVPATH
p2_start=$(fdisk -l /dev/$DEVPATH | grep $disk_part | awk '{print $2}' | tr -d '[[:space:]]')
echo "Partition start: $p2_start"
p2_end=$(fdisk -l /dev/$DEVPATH | grep $disk_part | awk '{print $3}' | tr -d '[[:space:]]')
echo "Partition end: $p2_end"

disk_size=$(blockdev --getsize /dev/$disk)
echo "Disk size: $disk_size"

if [ ! $(($disk_size-$p2_end)) -ge 10485760 ]; then
  echo "No need to resize physical, exiting."
  resize2fs ${disk_part} || true
  touch $MARKER
  exit 0
fi

p2_new_end=$((disk_size-10))

echo "Resizing $disk_part from $p2_end to $p2_new_end"

set +e
fdisk /dev/$DEVPATH <<EOF
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

echo "Resized persist. Rebooting."
if ! systemctl reboot ; then
  reboot
fi
