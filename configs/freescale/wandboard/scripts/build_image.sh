#!/bin/bash
if [ $EUID != 0 ]; then
    echo "This script requires sudo, so it might not work."
fi

set -e

if [ -z "$WANDBOARD_IMAGE" ]; then
    echo "Please set WANDBOARD_IMAGE to the path to the output image."
    exit 1
fi

if [[ "$WANDBOARD_IMAGE" != /* ]]; then
    # the "make" command is run from the skiff root,
    # it's most intuitive to take that as the base path
    WANDBOARD_IMAGE=$SKIFF_ROOT_DIR/$WANDBOARD_IMAGE
fi

echo "Allocating sparse image..."
fallocate -l 1G $WANDBOARD_IMAGE

echo "Setting up loopback device..."
export WANDBOARD_SD=$(losetup --show -fP $WANDBOARD_IMAGE)
function cleanup {
  echo "Removing loopback device..." || true
  sync || true
  losetup -d $WANDBOARD_SD || true
}
trap cleanup EXIT

if [ -z "${WANDBOARD_SD}" ] || [ ! -b ${WANDBOARD_SD} ]; then
    echo "Failed to setup loop device."
    exit 1
fi


# Setup no interactive since we know its a brand new file.
export SKIFF_NO_INTERACTIVE=1
export DISABLE_CREATE_SWAPFILE=1

echo "Using loopback device at ${WANDBOARD_SD}"
$SKIFF_CURRENT_CONF_DIR/scripts/format_sd.sh
$SKIFF_CURRENT_CONF_DIR/scripts/install_sd.sh
