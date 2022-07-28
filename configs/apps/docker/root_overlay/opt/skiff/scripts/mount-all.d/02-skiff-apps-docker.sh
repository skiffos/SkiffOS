#!/bin/bash

DOCKER_SERVICE=/usr/lib/systemd/system/docker.service
DOCKER_CONFD=/etc/systemd/system/docker.service.d
DOCKER_PERSIST=${SKIFF_PERSIST}/docker

# Grab the default docker execstart
mkdir -p ${DOCKER_CONFD}
if [ -f $DOCKER_SERVICE ]; then
    DOCKER_EXECSTART=$(cat $DOCKER_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

# Setup Docker mount, if applicable.
if [ -f $DOCKER_SERVICE ]; then
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_PERSIST=$(realpath ${DOCKER_PERSIST})
    mkdir -p ${DOCKER_PERSIST}
    DOCKER_EXECSTART+=" --data-root=\"$DOCKER_PERSIST\""

    echo "Configuring Docker to use systemd-journald"
    DOCKER_EXECSTART+=" --log-driver=journald"

    echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART\n" > $DOCKER_CONFD/execstart.conf
fi
