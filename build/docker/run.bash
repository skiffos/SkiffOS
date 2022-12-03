#!/bin/bash
set -eo pipefail

if [ -d ./build/docker ]; then
    cd ./build/docker
fi

CONTAINER_NAME=$1
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME="skiffos-build"
else
    shift
fi

TUID=${UID}
TGID=$(id -g)
TUIDGID="${TUID} ${TGID}"

echo "Using container name $CONTAINER_NAME"
PROJECT_ROOT=$(git rev-parse --show-toplevel)
docker rm -f skiff-build 2>/dev/null || true
docker run --rm -it \
       --privileged \
       --name=$CONTAINER_NAME \
       -e SKIFF_TUIDGID="$TUIDGID" \
       -e SKIFF_WORKSPACE="$SKIFF_WORKSPACE" \
       -e SKIFF_CONFIG="$SKIFF_CONFIG" \
       --workdir=/skiffos \
       --mount type=bind,source=${PROJECT_ROOT},target="/skiffos" \
       skiffos/build:latest $@
