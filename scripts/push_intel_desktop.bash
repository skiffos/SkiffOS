#!/bin/bash
set -eo pipefail
set -x

TARGET_HOST=$1
if [ -z "${TARGET_HOST}" ]; then
    echo "usage: $0 target-host-name"
    exit 1
fi
TARGET=root@${TARGET_HOST}:/mnt/persist/boot

if [ ! -d ./workspaces ]; then
    echo "please run from the root dir: ./scripts/push_image.sh"
    exit 1
fi

RS="rsync -rv --progress --sparse"

SKIFF_ROOT=${SKIFF_ROOT:-.}
SKIFF_WORKSPACE=${SKIFF_WORKSPACE:-default}
WORKSPACE_DIR=${SKIFF_ROOT}/workspaces/${SKIFF_WORKSPACE}
IMAGES_DIR=${WORKSPACE_DIR}/images
UIMG_PATH=${IMAGES_DIR}/bzImage
SQUASHFS_PATH="${IMAGES_DIR}/rootfs.squashfs"
SKIFF_INIT_PATH="${IMAGES_DIR}/skiff-init"

skiff_release_path="${IMAGES_DIR}/skiff-release"
if [ ! -f "$skiff_release_path" ]; then
    echo "skiff-release not found, make sure Buildroot is done compiling."
    exit 1
fi

if [ ! -f "${SKIFF_INIT_PATH}/skiff-init-squashfs" ]; then
    echo "skiff-init-squashfs not found, make sure Buildroot is done compiling."
    exit 1
fi

skiff_release=$(cat $skiff_release_path | grep "VERSION=" | cut -d= -f2)
# add -1 to the end of the release to avoid refind problems
skiff_release="${skiff_release}-1"

echo "Copying squashfs..."
squashfs_filename=init-skiffos-${skiff_release}.squashfs
${RS} $SQUASHFS_PATH ${TARGET}/${squashfs_filename}

echo "Copying kernel..."
${RS} $UIMG_PATH ${TARGET}/$(basename $UIMG_PATH)-skiffos-${skiff_release}

echo "Copying skiff-init..."
${RS} ${SKIFF_INIT_PATH}/ ${TARGET}/skiff-init/
