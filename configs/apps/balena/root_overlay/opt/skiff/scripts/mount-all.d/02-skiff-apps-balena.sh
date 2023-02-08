#!/bin/bash

BALENA_ENGINE_SERVICE=/usr/lib/systemd/system/balena-engine.service
BALENA_ENGINE_CONFD=/etc/systemd/system/balena-engine.service.d
BALENA_ENGINE_PERSIST=$(realpath ${SKIFF_PERSIST}/balena-engine)

mkdir -p ${BALENA_ENGINE_CONFD} ${BALENA_ENGINE_PERSIST}
if [ -f $BALENA_ENGINE_SERVICE ]; then
    echo "Configuring balena-engine to use $BALENA_ENGINE_PERSIST"
    BALENA_ENGINE_EXECSTART=$(cat $BALENA_ENGINE_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
    BALENA_ENGINE_EXECSTART+=" --data-root=\"$BALENA_ENGINE_PERSIST\""

    echo "Configuring balena-engine to use systemd-journald"
    BALENA_ENGINE_EXECSTART+=" --log-driver=journald"

    echo "Configuring balena-engine to start with '$BALENA_ENGINE_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$BALENA_ENGINE_EXECSTART\n" > $BALENA_ENGINE_CONFD/execstart.conf
fi
