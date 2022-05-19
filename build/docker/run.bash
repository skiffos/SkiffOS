#!/bin/bash
set -eo pipefail

if [ -d ./build/docker ]; then
    cd ./build/docker
fi

CONTAINER_NAME=$1
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME="skiff-build"
else
    shift
fi

echo "Using container name $CONTAINER_NAME"

PROJECT_ROOT=$(git rev-parse --show-toplevel)
docker rm -f skiff-build 2>/dev/null || true
docker run --rm -it --name=$CONTAINER_NAME \
       -e SKIFF_WORKSPACE="$SKIFF_WORKSPACE" \
       -e SKIFF_CONFIG="$SKIFF_CONFIG" \
       --workdir=/home/buildroot/skiff \
       -v ${PROJECT_ROOT}:/home/buildroot/skiff \
       skiff/build:latest /bin/bash -i $@
