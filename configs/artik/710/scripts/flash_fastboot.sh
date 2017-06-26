#!/bin/bash
set -eo pipefail

OUTPUT_DIR="${SKIFF_BUILDROOT_DIR}/output"
IMAGES_DIR="${OUTPUT_DIR}/images"
FASTBOOT="fastboot"

if [ ! -f "${IMAGES_DIR}/modules.img" ]; then
    echo "Build process is not complete, missing output files."
    echo "Please run 'make configure compile' first."
    exit 1
fi

FBDEV="$(fastboot devices)"
if [ -z "$FBDEV" ] || echo $FBDEV | grep -q "no permissions"; then
    echo "Device is not in $FASTBOOT mode."
    echo "Please put the device in $FASTBOOT mode by either:"
    echo " - 'reboot2fastboot' on the device"
    echo " - interrupt boot process with serial monitor and type '$FASTBOOT 0' in u-boot prompt"
    echo "Once this is done, connect the board to your computer with a MicroUSB cable to the 'USB OTG' microUSB port."

    if [ "$EUID" != "0" ]; then
        echo "Note: you are not root. Fastboot might not find your device."
        if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
            read -p "Would you like me to try using sudo? [y/N] " -n 1 -r
            if ! [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Ok, not using sudo for now."
            else
                echo "Will try with sudo, you may be prompted..."
                FASTBOOT="sudo \"PATH=$PATH\" $FASTBOOT"
            fi
        fi
    fi
fi

cd ${IMAGES_DIR}
$FASTBOOT flash partmap ./sd_fuse/partmap_emmc.txt
$FASTBOOT flash 2ndboot ./sd_fuse/bl1-emmcboot.img
$FASTBOOT flash fip-loader fip-loader-emmc.img
$FASTBOOT flash fip-secure fip-secure.img
$FASTBOOT flash fip-nonsecure fip-nonsecure.img
$FASTBOOT flash env params_emmc.bin
$FASTBOOT flash boot boot.img
$FASTBOOT flash modules modules.img
$FASTBOOT flash rootfs rootfs.img
$FASTBOOT flash persist persist.img
$FASTBOOT reboot

echo "Flashing complete!"
