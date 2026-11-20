#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
mkdir -p ${IMAGES_DIR}/skiff-init
cp ${SKIFF_CURRENT_CONF_DIR}/resources/resize2fs.conf ${IMAGES_DIR}/skiff-init/resize2fs.conf
