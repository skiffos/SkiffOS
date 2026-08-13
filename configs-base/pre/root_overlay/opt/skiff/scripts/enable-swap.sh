#!/bin/bash
set -e

# TODO: switch to systemd.swap utility
# TODO: https://github.com/systemd/zram-generator

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected!"
  exit 1
fi

SKIFF_ENV_PATH=${SKIFF_ENV_PATH:=/etc/skiff/env}
if [ -n "${SKIFF_ENV_PATH}" ] && [ -f ${SKIFF_ENV_PATH} ]; then
    source ${SKIFF_ENV_PATH}
fi

SWAP_ENV_PATH=${SWAP_ENV_PATH:=/etc/skiff/swap.env}
if [ -n "${SWAP_ENV_PATH}" ] && [ -f ${SWAP_ENV_PATH} ]; then
    source ${SWAP_ENV_PATH}
fi

# PERSIST_MNT should have been set by SKIFF_ENV_PATH.
PERSIST_MNT=${PERSIST_MNT:=/mnt/persist}
SWAPFILE_PATH=${SWAPFILE_PATH:=${PERSIST_MNT}/primary.swap}

# Enable ZRAM if not already enabled.
# This will compress contents of RAM to avoid using the swapfile.
ZRAM_SIZE="${ZRAM_SIZE:-2048M}"
SWAP_LIST=$(swapon | cut -d" " -f1 | sed 1d) || true
if [ -z "${DISABLE_ZRAM}" ] && ! (echo "${SWAP_LIST}" | grep -q "/dev/zram0"); then
    echo "Enabling ZRAM at /dev/zram0..."
    modprobe zram || true
    # modprobe returns as soon as the module is loaded, but udev then opens the
    # freshly created zram0 to probe it. zramctl resets the device before sizing
    # it, and that reset fails with EBUSY while udev still holds it:
    #
    #   zramctl: /dev/zram0: failed to reset: Device or resource busy
    #   mkswap: error: swap area needs to be at least 40 KiB
    #   swapon: /dev/zram0: read swap header failed
    #
    # Every command in this block is `|| true` and swapon.service uses
    # `ExecStart=-`, so the sequence failed silently and the unit still went
    # green -- the system just came up without zram. Which boot wins the race
    # varies: across 30 identical devices running one image, 11 had zram and 19
    # did not.
    command -v udevadm >/dev/null 2>&1 && udevadm settle --timeout=10 || true
    zram_tries=0
    while ! zramctl -s ${ZRAM_SIZE} /dev/zram0 2>/dev/null; do
        zram_tries=$((zram_tries + 1))
        if [ "${zram_tries}" -ge 5 ]; then
            echo "zramctl could not size /dev/zram0 after ${zram_tries} tries."
            break
        fi
        sleep 1
    done
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
