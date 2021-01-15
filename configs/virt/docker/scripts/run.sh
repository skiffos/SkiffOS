#!/bin/sh

if docker rm -f skiff ; then
  sleep 3
fi

IMAGES_PATH="$BUILDROOT_DIR/images"
WORKING_PATH="$BUILDROOT_DIR/docker-run"
ROOTFS_PATH=${IMAGES_PATH}/docker-rootfs
PERSIST_PATH=${WORKING_PATH}/docker-persist
mkdir -p ${ROOTFS_PATH} ${PERSIST_PATH}
docker run -d --name=skiff \
  --entrypoint=/lib/systemd/systemd \
  --privileged \
  --workdir / \
  --cap-add=ALL \
  --net=host \
  --ipc=host \
  --uts=host \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v /dev:/dev \
  -v /lib/modules:/lib/modules \
  -v /run/udev:/run/udev \
  -v ${IMAGES_PATH}:/mnt/rootfs \
  -v ${PERSIST_PATH}:/mnt/persist \
  skiffos/skiffos
