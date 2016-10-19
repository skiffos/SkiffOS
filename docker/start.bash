#!/bin/bash

if docker rm -f skiff ; then
  sleep 3
fi

docker run -d --name=skiff \
  --privileged \
  --cap-add=NET_ADMIN \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  --tmpfs /run \
  --tmpfs /run/lock \
  -t \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $(pwd)/rootfs:/mnt/rootfs \
  -v $(pwd)/persist:/mnt/persist \
  paralin/skiffos
