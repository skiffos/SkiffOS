#!/bin/bash
set -e

IMAGE_NAME=paralin/skiffos
IMAGE_TAG=latest
IMAGES_PATH="$BUILDROOT_DIR/output/images"
roottar="${IMAGES_PATH}/rootfs.tar"

mkdir -p ${SKIFF_DOCKER_MOUNT}/rootfs ${SKIFF_DOCKER_MOUNT}/persist \
  ${IMAGES_PATH}/rootfs_part

cp ${IMAGES_PATH}/rootfs.tar ${SKIFF_DOCKER_ROOT}/rootfs.tar
rsync -rav --no-perms --no-owner --no-group --delete \
  ${IMAGES_PATH}/rootfs_part/ ${SKIFF_DOCKER_MOUNT}/rootfs/

pushd ${SKIFF_DOCKER_ROOT}
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
popd
