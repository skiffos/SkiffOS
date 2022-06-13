#!/bin/bash
if [ $EUID != 0 ]; then
    echo "This script requires sudo, so it might not work."
fi

set -e

if [ -z "$STARFIVE_IMAGE" ]; then
    echo "Please set STARFIVE_IMAGE to the path to the output image."
    exit 1
fi

if [[ "$STARFIVE_IMAGE" != /* ]]; then
    # the "make" command is run from the skiff root,
    # it's most intuitive to take that as the base path
    STARFIVE_IMAGE=$SKIFF_ROOT_DIR/$STARFIVE_IMAGE
fi

echo "Allocating sparse image..."
fallocate -l 1G $STARFIVE_IMAGE

echo "Setting up loopback device..."
export STARFIVE_SD=$(losetup --show -fP $STARFIVE_IMAGE)
function cleanup {
  echo "Removing loopback device..." || true
  sync || true
  losetup -d $STARFIVE_SD || true
}
trap cleanup EXIT

if [ -z "${STARFIVE_SD}" ] || [ ! -b ${STARFIVE_SD} ]; then
    echo "Failed to setup loop device."
    exit 1
fi


# Setup no interactive since we know its a brand new file.
export SKIFF_NO_INTERACTIVE=1
export DISABLE_CREATE_SWAPFILE=1

echo "Using loopback device at ${STARFIVE_SD}"
$SKIFF_CURRENT_CONF_DIR/scripts/format_sd.sh
$SKIFF_CURRENT_CONF_DIR/scripts/install_sd.sh
