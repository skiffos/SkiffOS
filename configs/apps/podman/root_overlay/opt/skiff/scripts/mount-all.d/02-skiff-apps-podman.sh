#!/bin/bash

PODMAN_SERVICE=/usr/lib/systemd/system/podman.service
PODMAN_CONFD=/etc/systemd/system/podman.service.d
PODMAN_PERSIST=${SKIFF_PERSIST}/podman

# Grab the default podman execstart
mkdir -p ${PODMAN_CONFD}
if [ -f $PODMAN_SERVICE ]; then
    PODMAN_EXECSTART=$(cat $PODMAN_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

# Setup Podman mount, if applicable.
if [ -f $PODMAN_SERVICE ]; then
    echo "Configuring Podman to use $PODMAN_PERSIST"
    PODMAN_PERSIST=$(realpath ${PODMAN_PERSIST})
    mkdir -p ${PODMAN_PERSIST}
    PODMAN_EXECSTART+=" --root=\"$PODMAN_PERSIST\""

    echo "Configuring Podman to use crun"
    PODMAN_EXECSTART+=" --runtime=crun"

    echo "Configuring Podman to start with '$PODMAN_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$PODMAN_EXECSTART\n" > $PODMAN_CONFD/execstart.conf
fi
