#!/bin/bash

PODMAN_SERVICE=/usr/lib/systemd/system/podman.service
PODMAN_CONFD=/etc/systemd/system/podman.service.d
PODMAN_PERSIST=${SKIFF_PERSIST}/podman
PODMAN_PERSIST=$(realpath ${PODMAN_PERSIST})

# make podman persist dir
mkdir -p ${PODMAN_PERSIST}

# Grab the default podman execstart
mkdir -p ${PODMAN_CONFD}
if [ -f $PODMAN_SERVICE ]; then
    PODMAN_EXECSTART=$(cat $PODMAN_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

# If /var/lib/containers exists, remove it.
if [ -e /var/lib/containers ]; then
    rm -rf /var/lib/containers
fi

# Symlink /var/lib/containers to /mnt/persist/skiff/podman
ln -fs ${PODMAN_PERSIST} /var/lib/containers

# Setup Podman mount, if applicable.
if [ -f $PODMAN_SERVICE ]; then
    echo "Configuring Podman to use $PODMAN_PERSIST"
    PODMAN_EXECSTART+=" --root=\"$PODMAN_PERSIST\""

    echo "Configuring Podman to use crun"
    PODMAN_EXECSTART+=" --runtime=crun"

    echo "Configuring Podman to use NoPivotRoot"
    PODMAN_EXECSTART+=" --no-pivot"

    echo "Configuring Podman to start with '$PODMAN_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$PODMAN_EXECSTART\n" > $PODMAN_CONFD/execstart.conf
fi
