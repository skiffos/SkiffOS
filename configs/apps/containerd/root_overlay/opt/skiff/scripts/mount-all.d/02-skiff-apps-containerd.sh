#!/bin/bash

CONTAINERD_SERVICE=/usr/lib/systemd/system/containerd.service
CONTAINERD_CONFD=/etc/systemd/system/containerd.service.d
CONTAINERD_PERSIST=$(realpath ${SKIFF_PERSIST}/containerd)

mkdir -p ${CONTAINERD_CONFD} ${CONTAINERD_PERSIST}
if [ -f $CONTAINERD_SERVICE ]; then
    echo "Configuring containerd to use $CONTAINERD_PERSIST"
    CONTAINERD_EXECSTART=$(cat $CONTAINERD_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
    CONTAINERD_EXECSTART+=" --root=\"$CONTAINERD_PERSIST\""

    echo "Configuring Docker to start with '$CONTAINERD_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$CONTAINERD_EXECSTART\n" > $CONTAINERD_CONFD/execstart.conf
fi
