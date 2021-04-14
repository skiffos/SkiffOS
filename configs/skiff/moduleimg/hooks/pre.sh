#!/bin/bash
set -eo pipefail

BR2_CONFIG=${SKIFF_BUILDROOT_DIR}/.config

if grep -q "BR2_LINUX_KERNEL=y" ${BR2_CONFIG}; then
    echo "Building modules image..."
    ${SKIFF_CURRENT_CONF_DIR}/scripts/make_modules_image.sh
else
    echo "Skipping modules image, no kernel build was configured."
fi
