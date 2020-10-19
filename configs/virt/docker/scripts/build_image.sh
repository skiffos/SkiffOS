#!/bin/bash
set -ex

RSYNC_CMD="rsync -rav --no-perms --no-owner --no-group --delete "
IMAGE_NAME=skiffos/skiffos
IMAGE_TAG=latest
IMAGES_PATH="$BUILDROOT_DIR/output/images"
roottar="${IMAGES_PATH}/rootfs.tar"

cd ${IMAGES_PATH}
cp \
	${SKIFF_CURRENT_CONF_DIR}/resources/Dockerfile \
       	${IMAGES_PATH}/
docker build -f Dockerfile -t "${IMAGE_NAME}:${IMAGE_TAG}" .
