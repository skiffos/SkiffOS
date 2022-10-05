#!/bin/bash
set -eo pipefail

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target
mkdir -p ${TARGET_DIR}/boot ${TARGET_DIR}/persist

# Mask systemd-sysupdate.service
ln -fs /dev/null "${TARGET_DIR}/etc/systemd/system/systemd-sysupdate.service"
