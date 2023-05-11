#!/bin/bash

DOCKER_SERVICE=/usr/lib/systemd/system/docker.service
DOCKER_CONFD=/etc/systemd/system/docker.service.d

# Use environment-set DOCKER_PERSIST if available, otherwise use default path.
DOCKER_PERSIST_DEFAULT=$(realpath ${SKIFF_PERSIST}/docker)
DOCKER_PERSIST=${DOCKER_PERSIST:=${DOCKER_PERSIST_DEFAULT}}

mkdir -p ${DOCKER_CONFD} ${DOCKER_PERSIST}
if [ -f $DOCKER_SERVICE ]; then
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_EXECSTART=$(cat $DOCKER_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
    DOCKER_EXECSTART+=" --data-root=\"$DOCKER_PERSIST\""

    echo "Configuring Docker to use systemd-journald"
    DOCKER_EXECSTART+=" --log-driver=journald"

    echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART\n" > $DOCKER_CONFD/execstart.conf
fi
