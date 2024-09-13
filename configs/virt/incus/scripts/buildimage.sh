#!/bin/bash
set -ex

IMAGE_NAME=skiffos/testing
CONTAINER=skiff
OUTPUT_PATH="$BUILDROOT_DIR/output"
IMAGES_PATH="$BUILDROOT_DIR/images"
WORKING_PATH="${BUILDROOT_DIR}/nspawn-run"
PERSIST_PATH="${WORKING_PATH}/nspawn-persist"
INCUS_IMAGE_PATH="${IMAGE_PATH}/incus.tar.gz"
roottar="${IMAGES_PATH}/rootfs.tar"

if ! command -v incus >/dev/null 2>&1; then
	echo "Failed to find the incus command. Is incus installed on your host system?"
	exit 1
fi

mkdir -p "${PERSIST_PATH}"
TMPDIR="${WORKING_PATH}/incus-tmp"
trap 'rm -rf "$TMPDIR";' EXIT
rm -rf "$TMPDIR"
mkdir -p "${TMPDIR}/rootfs"
tar -xf "$roottar" -C "$TMPDIR/rootfs"
pushd "$TMPDIR"
creationtime="$(date +%s)"
default_metadata="architecture: x86_64
creation_date: $creationtime
properties:
  description: SkiffOS
  os: Linux x86
  release: unknown"
echo "${INCUS_METADATA:-"${default_metadata}"}" >"${TMPDIR}/metadata.yaml"
tar caf "${INCUS_IMAGE_PATH}" rootfs metadata.yaml
popd

echo "Incus image generated successfully as ${IMAGE_NAME}"
