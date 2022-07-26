#!/bin/bash
set -e

# TODO: switch to systemd.swap utility
# TODO: https://github.com/systemd/zram-generator

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected, bailing out!"
  exit 1
fi

ENV_PATH=/etc/skiff-swap.env
PERSIST_MNT=/mnt/persist
SWAPFILE_PATH=$PERSIST_MNT/primary.swap
if [ -f ${ENV_PATH} ]; then
    source ${ENV_PATH}
fi

SWAP_LIST=$(swapon | cut -d" " -f1 | sed 1d) || true

# Enable ZRAM if not already enabled.
# This will compress contents of RAM to avoid using the swapfile.
ZRAM_SIZE="${ZRAM_SIZE:-2048M}"
if [ -z "${DISABLE_ZRAM}" ] && ! (echo "${SWAP_LIST}" | grep -q "/dev/zram0"); then
    echo "Enabling ZRAM at /dev/zram0..."
    modprobe zram || true
    zramctl -s ${ZRAM_SIZE} /dev/zram0 || true
    swapoff /dev/zram0 2>/dev/null || true
    mkswap /dev/zram0 || true
    # set priority to -10
    if ! swapon -p -10 /dev/zram0 ; then
        echo "Failed to enable zram0 swap, continuing..."
    else
        echo "ZRAM enabled with size ${ZRAM_SIZE}."
    fi
fi

# Swap file, in case we run out of RAM.
SWAPFILE_SIZE=${SWAPFILE_SIZE:-2048}
if [ -n "${DISABLE_SWAPFILE}" ] || [ -z "${SWAPFILE_PATH}" ]; then
    echo "Swapfile is disabled."
    exit 0
fi

if mountpoint -q $PERSIST_MNT; then
  echo "Found persist drive at $PERSIST_MNT"
else
  echo "Cannot find persist mount point, skipping swapfile."
  exit 0
fi

if swapon -s | grep -q "${SWAPFILE_PATH}" ; then
    echo "$SWAPFILE_PATH is already initialized."
    exit 0
fi

# Allocate swap file if it doesn't exist
if [ ! -f $SWAPFILE_PATH ]; then
  echo "Allocating swapfile at $SWAPFILE_PATH of size $SWAPFILE_SIZE"
  # fallocate: does not work: swapfile cannot have holes
  # fallocate -l ${SWAPFILE_SIZE}Mb $SWAPFILE_PATH
  ionice -c 3 dd if=/dev/zero of=$SWAPFILE_PATH bs=1M count=${SWAPFILE_SIZE}
  echo "Done allocating swapfile."
fi

chmod 600 $SWAPFILE_PATH
mkswap $SWAPFILE_PATH
# set priority to -100
swapon -p -100 $SWAPFILE_PATH
