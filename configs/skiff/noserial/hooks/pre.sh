#!/bin/bash

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target

echo "Disabling serial-getty@ in target..."
SYSTEMD_DIR=${TARGET_DIR}/usr/lib/systemd/system
if [ ! -d ${SYSTEMD_DIR} ]; then
    echo "Could not find systemd dir at ${SYSTEMD_DIR}"
    exit 1
fi
rm -f ${SYSTEMD_DIR}/serial-getty@.service.d/buildroot-console.conf

eval $(cat ${SKIFF_BUILDROOT_DIR}/.config |\
           grep -m1 "BR2_TARGET_GENERIC_GETTY_PORT=" |\
           xargs)
if [ -n "$BR2_TARGET_GENERIC_GETTY_PORT" ] ; then
    echo "Creating systemd mask for ${BR2_TARGET_GENERIC_GETTY_PORT}"
    ln -fs /dev/null "${TARGET_DIR}/etc/systemd/system/serial-getty@${BR2_TARGET_GENERIC_GETTY_PORT}.service"
fi
