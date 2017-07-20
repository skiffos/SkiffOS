#!/bin/bash

set -eo pipefail

if head=`git rev-parse --verify --short HEAD`; then
    if ver=`git describe --tags HEAD`; then
        export SKIFF_VERSION=$ver
    else
        export SKIFF_VERSION=$head
    fi
    export SKIFF_VERSION_COMMIT=$head
else
    export SKIFF_VERSION="unknown"
    export SKIFF_VERSION_COMMIT="unknown"
fi
