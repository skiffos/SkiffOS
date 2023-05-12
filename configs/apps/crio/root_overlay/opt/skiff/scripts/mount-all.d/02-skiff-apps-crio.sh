#!/bin/bash

# Override /var/lib/containers
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

# Override /var/lib/crio
CRIO_PERSIST=${CRIO_PERSIST:=${SKIFF_PERSIST}/crio}
CRIO_PERSIST=$(realpath ${CRIO_PERSIST})

# Make crio persist dir
mkdir -p ${CRIO_PERSIST}

# If /var/lib/crio exists, remove it.
if [ -e /var/lib/crio ]; then
    rm -rf /var/lib/crio
fi

# Symlink /var/lib/crio to /mnt/persist/skiff/crio
ln -fs ${CRIO_PERSIST} /var/lib/crio
