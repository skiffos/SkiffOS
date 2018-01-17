#!/bin/bash
set -eo pipefail

cp ../../workspaces/${SKIFF_WORKSPACE}/images/rootfs.tar ./rootfs.tar
docker build -t "paralin/skiffos:latest" .
