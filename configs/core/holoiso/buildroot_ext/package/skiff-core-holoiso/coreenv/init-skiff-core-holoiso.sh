#!/bin/bash
set -eo pipefail

if [ ! -f /etc/holoiso-branch ]; then
    echo "Non-holoiso machine detected! Exiting."
    echo "This is meant to be run in the skiff-core-holoiso image."
    exit 1
fi

mkdir -p /home/core
chown core:core /home/core
if [ ! -d /home/core/Desktop ]; then
    echo "copying skeleton to /home/core"
    rsync -ra --chown core:core /etc/skel/ /home/core/
fi
