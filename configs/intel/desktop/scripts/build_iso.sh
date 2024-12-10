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

echo "Creating ISO image..."
mkisofs -o $INTEL_DESKTOP_IMAGE.iso -b boot/grub/i386-pc/eltorito.img -c boot.catalog -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "SkiffOS" $SKIFF_CURRENT_CONF_DIR/resources

echo "ISO image created at $INTEL_DESKTOP_IMAGE.iso"
