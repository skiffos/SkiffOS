#!/bin/bash
set -eo pipefail

export container=wsl
export PATH=/usr/lib/systemd:/usr/sbin:/usr/bin
export SYSTEMD_IGNORE_CHROOT=1

# systemd will mount over /dev/shm
# remove it if it's a file
if [ ! -d /dev/shm ]; then
    rm /dev/shm 2>/dev/null || true
fi
mkdir -p /run/shm || true

echo "SkiffOS init: executing systemd inside PID namespace..."
set -x
mount --make-shared /
if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
fi
exec /usr/lib/systemd/systemd \
     --log-target=kmsg
