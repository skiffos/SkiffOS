#!/bin/bash

if [ $EUID != 0 ]; then
    echo "This script requires sudo, so it might not work."
fi

set -e

if [ -z "$PI_IMAGE" ]; then
    echo "Please set PI_IMAGE and try agian."
    exit 1
fi

if [[ "$PI_IMAGE" != /* ]]; then
    PI_IMAGE=$WORKSPACE_DIR/$PI_IMAGE
fi

echo "Allocating image..."
dd if=/dev/zero of=$PI_IMAGE bs=1GB count=1

echo "Setting up loopback device..."
PI_SD=$(sudo losetup --show -fP $PI_IMAGE)

# Setup no interactive since we know its a brand new file.
export SKIFF_NO_INTERACTIVE=1

$SKIFF_CURRENT_CONF_DIR/scripts/format_sd.sh
$SKIFF_CURRENT_CONF_DIR/scripts/install_sd.sh

echo "Removing loopback device..."
sudo losetup -d $PI_SD