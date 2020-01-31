#!/bin/bash

echo "Copying grub configuration to target..."
cp ${SKIFF_CURRENT_CONF_DIR}/resources/grub/grub.cfg \
	 ${SKIFF_BUILDROOT_DIR}/output/images/grub.cfg

echo "Building target filesystem image..."
${SKIFF_CURRENT_CONF_DIR}/scripts/build_image.sh

