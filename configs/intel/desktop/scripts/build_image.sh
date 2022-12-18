#!/bin/bash

if [ $EUID != 0 ]; then
    echo "This script requires sudo, so it might not work."
fi

set -e

if [ -z "$INTEL_DESKTOP_IMAGE" ]; then
    echo "Please set INTEL_DESKTOP_IMAGE to the path to the output image."
    exit 1
fi

if [[ "$INTEL_DESKTOP_IMAGE" != /* ]]; then
    # the "make" command is run from the skiff root,
    # it's most intuitive to take that as the base path
    INTEL_DESKTOP_IMAGE=$SKIFF_ROOT_DIR/$INTEL_DESKTOP_IMAGE
fi

echo "Allocating sparse image..."
fallocate -l 1.5G $INTEL_DESKTOP_IMAGE

echo "Setting up loopback device..."
export INTEL_DESKTOP_DISK=$(losetup --show -fP $INTEL_DESKTOP_IMAGE)
function cleanup {
  echo "Removing loopback device..." || true
  sync || true
  losetup -d $INTEL_DESKTOP_DISK || true
}
trap cleanup EXIT

if [ -z "${INTEL_DESKTOP_DISK}" ] || [ ! -b ${INTEL_DESKTOP_DISK} ]; then
    echo "Failed to setup loop device."
    exit 1
fi

# Setup no interactive since we know its a brand new file.
export SKIFF_NO_INTERACTIVE=1
export DISABLE_CREATE_SWAPFILE=1

echo "Using loopback device at ${INTEL_DESKTOP_DISK}"
$SKIFF_CURRENT_CONF_DIR/scripts/format_sd.sh
$SKIFF_CURRENT_CONF_DIR/scripts/install_sd.sh
