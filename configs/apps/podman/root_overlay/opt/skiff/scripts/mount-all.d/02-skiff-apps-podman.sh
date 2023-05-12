#!/bin/bash

PODMAN_SERVICE=/usr/lib/systemd/system/podman.service
PODMAN_CONFD=/etc/systemd/system/podman.service.d

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

# Grab the default podman execstart
mkdir -p ${PODMAN_CONFD}
if [ -f $PODMAN_SERVICE ]; then
    PODMAN_EXECSTART=$(cat $PODMAN_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

# Setup Podman mount, if applicable.
if [ -f $PODMAN_SERVICE ]; then
    echo "Configuring Podman to use $CONTAINERS_PERSIST"
    PODMAN_EXECSTART+=" --root=\"$CONTAINERS_PERSIST\""

    echo "Configuring Podman to use crun"
    PODMAN_EXECSTART+=" --runtime=crun"

    echo "Configuring Podman to use NoPivotRoot"
    PODMAN_EXECSTART+=" --no-pivot"

    echo "Configuring Podman to start with '$PODMAN_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$PODMAN_EXECSTART\n" > $PODMAN_CONFD/execstart.conf
fi
