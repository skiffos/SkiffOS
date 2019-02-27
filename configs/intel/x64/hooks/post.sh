#!/bin/bash

echo "Building target filesystem image..."
cp ${SKIFF_CURRENT_CONF_DIR}/resources/grub/grub.cfg \
	${SKIFF_BUILDROOT_DIR}/output/images/efi-part/EFI/BOOT/grub.cfg
${SKIFF_CURRENT_CONF_DIR}/scripts/build_image.sh

