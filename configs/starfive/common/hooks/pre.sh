#!/bin/bash

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images

echo "Prepending header to fw_payload.bin"
perl -e 'print pack("l", (stat @ARGV[0])[7])' ${IMAGES_DIR}/fw_payload.bin > ${IMAGES_DIR}/fw_payload.bin.out
cat ${IMAGES_DIR}/fw_payload.bin >> ${IMAGES_DIR}/fw_payload.bin.out
