#!/bin/sh

if docker rm -f skiff ; then
  sleep 3
fi

IMAGES_PATH="$BUILDROOT_DIR/output/images"
WORKING_PATH="$BUILDROOT_DIR/output/docker-run"
ROOTFS_PATH=${IMAGES_PATH}/docker-rootfs
PERSIST_PATH=${WORKING_PATH}/docker-persist
mkdir -p ${ROOTFS_PATH} ${PERSIST_PATH}
docker run -d --name=skiff \
  --privileged \
  --cap-add=NET_ADMIN \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  --tmpfs /run \
  --tmpfs /run/lock \
  -t \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v ${IMAGES_PATH}:/mnt/rootfs \
  -v ${PERSIST_PATH}:/mnt/persist \
  paralin/skiffos
