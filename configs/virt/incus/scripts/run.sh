#!/bin/bash
set -eu

IMAGE_NAME=skiffos/testing
CONTAINER=skiff
IMAGES_PATH="$BUILDROOT_DIR/images"
INCUS_IMAGE_PATH="${IMAGES_PATH}/incus.tar.gz"

if ! command -v incus >/dev/null 2>&1; then
	echo "Failed to find the incus command. Is incus installed on your host system?"
	exit 1
fi

if ! [[ -f "${INCUS_IMAGE_PATH}" ]] >/dev/null; then
	echo "${INCUS_IMAGE_PATH} not found. Did you execute \`make cmd/virt/incus/buildimage\`?"
	exit 1
fi

if incus image show "${IMAGE_NAME}" >/dev/null 2>&1; then
	incus image delete "${IMAGE_NAME}"
fi
incus image import --alias "${IMAGE_NAME}" "${INCUS_IMAGE_PATH}"

storage_pool="$(incus storage list -c n -f csv | head -n 1)"

if ! incus storage volume show "$storage_pool" skiff-persist >/dev/null 2>&1; then
	incus storage volume create "$storage_pool" "skiff-persist"
fi

if incus info "${CONTAINER}" > /dev/null 2>&1; then
	incus stop "${CONTAINER}" || :
	incus rm -f "${CONTAINER}" || :
fi

incus create "${IMAGE_NAME}" "${CONTAINER}"
incus storage volume attach "$storage_pool" skiff-persist skiff /mnt/persist
#incus config device add "${CONTAINER}" images-disk source="${IMAGES_PATH}" path=/mnt/rootfs
incus start "${CONTAINER}"

echo "Incus container started as ${CONTAINER}."
