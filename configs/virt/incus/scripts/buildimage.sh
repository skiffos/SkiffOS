#!/bin/bash
set -eu

IMAGE_NAME=skiffos/testing
CONTAINER=skiff
#IMAGES_PATH="$BUILDROOT_DIR/images"

if ! command -v incus >/dev/null 2>&1; then
	echo "Failed to find the incus command. Is incus installed on your host system?"
	exit 1
fi

# create utility container
echo "Creating builder container..."
trap 'incus rm -f skiff-builder' EXIT
incus create images:alpine/3.20 skiff-builder
incus config device add skiff-builder buildsource disk shift=true source="${BUILDROOT_DIR}" path="/mnt/build"
incus start skiff-builder
for i in {1..10}
do
  echo "Install container dependencies (attempt $i/10)..."
  if incus exec skiff-builder -- apk add tar bash
  then
    break
  elif [[ "$i" == 10 ]]
  then
    echo "Failed to install container dependencies"
    exit 1
  fi
  sleep 3
done
echo "done."

creationtime="$(date +%s)"
default_metadata="architecture: x86_64
creation_date: $creationtime
properties:
  description: SkiffOS
  os: Linux x86
  release: unknown"

TMPDIR_HOST="${BUILDROOT_DIR}/incus-tmp"
touch "${BUILDROOT_DIR}/uid_test"
trap 'rm "${BUILDROOT_DIR}/uid_test"; incus rm -f skiff-builder' EXIT

incus exec skiff-builder -- bash <<EOF
set -eux

OUTPUT_PATH="/mnt/build/output"
IMAGES_PATH="/mnt/build/images"
INCUS_IMAGE_PATH="\${IMAGES_PATH}/incus.tar.gz"
roottar="\${IMAGES_PATH}/rootfs.tar"
TMPDIR="/tmp/skiff/incus"

rm -rf "\$TMPDIR"
trap 'rm -rf \${TMPDIR}' EXIT
mkdir -p "\${TMPDIR}/rootfs"
tar --same-owner -xf "\$roottar" -C "\${TMPDIR}/rootfs"
cd "\$TMPDIR"
echo "${INCUS_METADATA:-"${default_metadata}"}" > "\${TMPDIR}/metadata.yaml"
tar caf "\${INCUS_IMAGE_PATH}" rootfs metadata.yaml
host_user_id="\$(stat -c '%u' "/mnt/build/uid_test")"
host_group_id="\$(stat -c '%g' "/mnt/build/uid_test")"
chown "\${host_user_id}:\${host_group_id}" "\${INCUS_IMAGE_PATH}"
EOF

echo "Incus image generated successfully as ${IMAGE_NAME}"
