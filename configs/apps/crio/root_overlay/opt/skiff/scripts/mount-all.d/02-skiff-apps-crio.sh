#!/bin/bash

CONTAINERS_PERSIST=${CONTAINERS_PERSIST:=${SKIFF_PERSIST}/containers}
CONTAINERS_PERSIST=$(realpath ${CONTAINERS_PERSIST})

# Make containers persist dir
mkdir -p ${CONTAINERS_PERSIST}

# If /var/lib/containers exists, remove it.
if [ -e /var/lib/containers ]; then
    rm -rf /var/lib/containers
fi

# Symlink /var/lib/containers to /mnt/persist/skiff/containers
ln -fs ${CONTAINERS_PERSIST} /var/lib/containers
