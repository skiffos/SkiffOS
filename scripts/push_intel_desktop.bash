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
    echo "please run from the root dir: ./scripts/push_image.bash"
    exit 1
fi

RS="rsync -rv --progress"

SKIFF_ROOT=${SKIFF_ROOT:-.}
SKIFF_WORKSPACE=${SKIFF_WORKSPACE:-default}
WORKSPACE_DIR=${SKIFF_ROOT}/workspaces/${SKIFF_WORKSPACE}
IMAGES_DIR=${WORKSPACE_DIR}/images
UIMG_PATH=${IMAGES_DIR}/bzImage
SQUASHFS_PATH="${IMAGES_DIR}/rootfs.squashfs"
SKIFF_INIT_PATH="${IMAGES_DIR}/skiff-init"

if [ ! -f "$UIMG_PATH" ] || [ ! -f "$SQUASHFS_PATH" ]; then
    echo "bzImage or rootfs.squashfs not found, make sure Buildroot is done compiling."
    exit 1
fi
if [ ! -f "${SKIFF_INIT_PATH}/skiff-init-squashfs" ]; then
    echo "skiff-init-squashfs not found, make sure Buildroot is done compiling."
    exit 1
fi

TARGET_HOSTNAME=root@${TARGET_HOST}
NEXT_DIR=/mnt/persist/boot/.next
ssh "$TARGET_HOSTNAME" "rm -rf ${NEXT_DIR}; mkdir -p ${NEXT_DIR}"

# Do not activate the slot until both files are completely uploaded.
echo "Copying kernel to next boot slot..."
${RS} "$UIMG_PATH" "${TARGET}/${NEXT_DIR##*/}/bzImage"
echo "Copying squashfs to next boot slot..."
${RS} "$SQUASHFS_PATH" "${TARGET}/${NEXT_DIR##*/}/init-skiffos.squashfs"
echo "Copying skiff-init to next boot slot..."
${RS} "${SKIFF_INIT_PATH}/" "${TARGET}/${NEXT_DIR##*/}/skiff-init/"

ssh "$TARGET_HOSTNAME" 'bash -s' <<'EOF'
set -eo pipefail
boot_dir=/mnt/persist/boot
next_dir=${boot_dir}/.next

if [ -d "${boot_dir}/previous" ]; then
    mv "${boot_dir}/previous" "${boot_dir}/.old-previous"
fi
if [ -d "${boot_dir}/current" ]; then
    mv "${boot_dir}/current" "${boot_dir}/previous"
else
    cp -a "${next_dir}" "${boot_dir}/previous"
fi
mv "${next_dir}" "${boot_dir}/current"
rm -rf "${boot_dir}/.old-previous"
sync
EOF
