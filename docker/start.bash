#!/bin/bash

DOCKER_TMP=${SKIFF_DOCKER_MOUNT:-"$(pwd)/../docker-mount"}
mkdir -p $DOCKER_TMP/persist/ $DOCKER_TMP/rootfs/

if docker rm -f systemd ; then
  sleep 1
fi
docker run -d --name=systemd \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  --tmpfs /run \
  --tmpfs /run/lock \
  -t \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $DOCKER_TMP/persist:/mnt/persist \
  -v $DOCKER_TMP/rootfs:/mnt/rootfs \
  -v /var/run/docker.sock:/var/run/docker.sock \
  paralin/skiff
