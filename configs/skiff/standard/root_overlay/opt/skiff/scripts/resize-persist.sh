#!/bin/bash
# set -eo pipefail

PERSIST_DEV=$(blkid | grep -m 1 'LABEL="persist"' | cut -d: -f1)
echo "Found persist at ${PERSIST_DEV}, performing filesystem check if necessary..."
FSCKFIX=yes fsck -y $PERSIST_DEV

DEVPATH=$PERSIST_DEV
echo "Disk partition detected ${DEVPATH}"
disk=$(lsblk -no pkname $DEVPATH)
echo "Disk detected at ${disk}."
part_num=$(lsblk -f /dev/$disk -o "MAJ:MIN" | tail -n1 | cut -d: -f2 | tr -d '[[:space:]]')
echo "Partition number detected as $part_num"
disk_part=$DEVPATH
p2_start=$(fdisk -l /dev/$disk | grep $disk_part | awk '{print $2}' | tr -d '[[:space:]]')
echo "Partition start: $p2_start"
p2_end=$(fdisk -l /dev/$disk | grep $disk_part | awk '{print $3}' | tr -d '[[:space:]]')
echo "Partition end: $p2_end"

disk_size=$(blockdev --getsize /dev/$disk)
echo "Disk size: $disk_size"

if [ ! $(($disk_size-$p2_end)) -ge 10485760 ]; then
  echo "No need to resize physical, exiting."
  if ! resize2fs ${disk_part} ; then
      echo "[ignored]"
  fi
  exit 0
fi

p2_new_end=$((disk_size-10))

echo "Resizing $disk_part from $p2_end to $p2_new_end"

set +e
fdisk /dev/$disk <<EOF
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

echo "Resized persist successfully."

