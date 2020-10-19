#!/bin/bash
set -eo pipefail

BR2_CONFIG=${SKIFF_BUILDROOT_DIR}/.config

if cat ${BR2_CONFIG} | grep -q "BR2_LINUX_KERNEL=y"; then
    echo "Building modules image..."
    ${SKIFF_CURRENT_CONF_DIR}/scripts/make_modules_image.sh
else
    echo "Skipping modules image, no kernel build was configured."
fi
