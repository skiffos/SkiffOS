#!/bin/bash
set -eu

IMAGE_NAME=skiffos/testing
CONTAINER=skiff
OUTPUT_PATH="$BUILDROOT_DIR/output"
IMAGES_PATH="$BUILDROOT_DIR/images"
INCUS_IMAGE_PATH="${IMAGES_PATH}/incus.tar.gz"
roottar="${IMAGES_PATH}/rootfs.tar"

TMPDIR="${BUILDROOT_DIR}/incus-tmp"
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
