#!/bin/bash

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target

echo "Creating disable serial console stamp..."
touch ${SKIFF_BUILDROOT_DIR}/images/.disable-serial-console

eval $(cat ${SKIFF_BUILDROOT_DIR}/.config |\
           grep -m1 "BR2_TARGET_GENERIC_GETTY_PORT=" |\
           xargs)
if [ -n "$BR2_TARGET_GENERIC_GETTY_PORT" ] ; then
    echo "Creating systemd mask for ${BR2_TARGET_GENERIC_GETTY_PORT}"
    ln -fs /dev/null "${TARGET_DIR}/etc/systemd/system/serial-getty@${BR2_TARGET_GENERIC_GETTY_PORT}.service"
fi
