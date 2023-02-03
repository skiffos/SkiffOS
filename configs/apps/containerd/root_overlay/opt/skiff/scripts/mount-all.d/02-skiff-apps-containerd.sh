#!/bin/bash

CONTAINERD_SERVICE=/usr/lib/systemd/system/containerd.service
CONTAINERD_CONFD=/etc/systemd/system/containerd.service.d
CONTAINERD_PERSIST=${SKIFF_PERSIST}/containerd

# Grab the default containerd execstart
mkdir -p ${CONTAINERD_CONFD}
if [ -f $CONTAINERD_SERVICE ]; then
    CONTAINERD_EXECSTART=$(cat $CONTAINERD_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

# Setup containerd mount, if applicable.
if [ -f $CONTAINERD_SERVICE ]; then
    echo "Configuring containerd to use $CONTAINERD_PERSIST"
    CONTAINERD_PERSIST=$(realpath ${CONTAINERD_PERSIST})
    mkdir -p ${CONTAINERD_PERSIST}
    CONTAINERD_EXECSTART+=" --root=\"$CONTAINERD_PERSIST\""

    echo "Configuring containerd to start with '$CONTAINERD_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$CONTAINERD_EXECSTART\n" > $CONTAINERD_CONFD/execstart.conf
fi
