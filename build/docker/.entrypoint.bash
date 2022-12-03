#!/bin/bash
set -e

TUIDGID=($SKIFF_TUIDGID)
TUID=${TUIDGID[0]}
TGID=${TUIDGID[1]}

NAME="skiffos"
addgroup --gid ${TGID} ${NAME}
adduser \
    --gid ${TGID} \
    --uid ${TUID} \
    --shell /bin/bash \
    --disabled-login \
    --gecos "" \
    ${NAME} >/dev/null

ARGS=$@
if [ "$ARGS" != "" ]; then
    ARGS="-c ${ARGS}"
fi
sudo -u \#${TUID} -- /bin/bash +e $ARGS
