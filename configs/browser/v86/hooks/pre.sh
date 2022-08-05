#!/bin/bash
set -eo pipefail

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target
if [ ! -d ${TARGET_DIR}/boot ]; then
    mkdir ${TARGET_DIR}/boot
fi
