#!/bin/bash
set -eo pipefail

if [ -d ./build/docker ]; then
    cd ./build/docker
fi

docker build -t "skiffos/build:latest" .
