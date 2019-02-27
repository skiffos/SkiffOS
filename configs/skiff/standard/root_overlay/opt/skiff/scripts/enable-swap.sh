#!/bin/bash
set -e

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected, bailing out!"
  exit 1
fi

PERSIST_MNT=/mnt/persist

if mountpoint -q $PERSIST_MNT; then
  echo "Found persist drive at $PERSIST_MNT"
else
  echo "Cannot find persist mount point, bailing."
  exit 1
fi

SWAPFILE_PATH=$PERSIST_MNT/primary.swap
# in mb
SWAPFILE_SIZE=2000
if [ -f /etc/skiff-swap.env ]; then
    source /etc/skiff-swap.env
fi

if swapon -s | grep -q "${SWAPFILE_PATH}" ; then
    echo "$SWAPFILE_PATH is already initialized."
    exit 0
fi

# Allocate swap file if it doesn't exist
if [ ! -f $SWAPFILE_PATH ]; then
  echo "Allocating swapfile at $SWAPFILE_PATH of size $SWAPFILE_SIZE"
  if ! fallocate -l ${SWAPFILE_SIZE}Mb $SWAPFILE_PATH ; then
      echo "Failed to use fallocate, trying dd..."
      dd if=/dev/zero of=$SWAPFILE_PATH bs=1M count=${SWAPFILE_SIZE}
  fi
fi
chmod 600 $SWAPFILE_PATH
mkswap $SWAPFILE_PATH

swapon $SWAPFILE_PATH
