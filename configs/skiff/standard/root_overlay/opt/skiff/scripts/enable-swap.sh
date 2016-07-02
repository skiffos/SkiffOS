#!/bin/bash
set -e

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected, bailing out!"
  exit 1
fi

INIT_ONCE=/run/skiff-swap-inited

if [ -f $INIT_ONCE ]; then
  echo "$INIT_ONCE exists, bailing out."
  exit 0
fi

PERSIST_MNT=/mnt/persist

if mountpoint -q $PERSIST_MNT; then
  echo "Found persist drive at $PERSIST_MNT"
else
  echo "Cannot find persist mount point, bailing."
  exit 1
fi

SWAPFILE_PATH=$PERSIST_MNT/primary.swap
SWAPFILE_SIZE=2G

# Allocate swap file if it doesn't exist
if [ ! -f $SWAPFILE_PATH ]; then
  echo "Allocating swapfile at $SWAPFILE_PATH of size $SWAPFILE_SIZE"
  fallocate -l $SWAPFILE_SIZE $SWAPFILE_PATH
  chmod 600 $SWAPFILE_PATH
  mkswap $SWAPFILE_PATH
fi

swapon $SWAPFILE_PATH
touch $INIT_ONCE
