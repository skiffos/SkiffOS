#!/bin/bash
set -e
RSYNC_CMD="rsync -rav --no-perms --no-owner --no-group --delete "

IMAGE_NAME=paralin/skiffos
IMAGE_TAG=latest
IMAGES_PATH="$BUILDROOT_DIR/output/images"
roottar="${IMAGES_PATH}/rootfs.tar"

mkdir -p ${SKIFF_DOCKER_ROOT}/rootfs ${SKIFF_DOCKER_ROOT}/persist \
  ${IMAGES_PATH}/rootfs_part

$RSYNC_CMD ${IMAGES_PATH}/rootfs.tar ${SKIFF_DOCKER_ROOT}/rootfs.tar
$RSYNC_CMD \
  ${IMAGES_PATH}/rootfs_part/ ${SKIFF_DOCKER_ROOT}/rootfs/

pushd ${SKIFF_DOCKER_ROOT}
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
popd
