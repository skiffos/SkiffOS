#!/bin/bash
set -eo pipefail

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target
if [ ! -d ${TARGET_DIR}/boot ]; then
    mkdir ${TARGET_DIR}/boot
fi

# Mask systemd-sysupdate.service
ln -fs /dev/null "${TARGET_DIR}/etc/systemd/system/systemd-sysupdate.service"
