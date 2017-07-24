#!/bin/bash

set -eo pipefail

if head=`git rev-parse --verify --short HEAD 2>/dev/null`; then
    if ver=`git describe --tags HEAD 2>/dev/null`; then
        export SKIFF_VERSION=$ver
    else
        export SKIFF_VERSION=$head
    fi
    export SKIFF_VERSION_COMMIT=$head
else
    export SKIFF_VERSION="unknown"
    export SKIFF_VERSION_COMMIT="unknown"
fi
