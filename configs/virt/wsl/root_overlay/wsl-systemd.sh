#!/bin/bash
set -eo pipefail

export container=wsl
export PATH=/usr/lib/systemd:/usr/sbin:/usr/bin
export SYSTEMD_IGNORE_CHROOT=1

# write PID file using host proc tree
if [ ! -d /host-proc ]; then
    echo "SkiffOS init: /host-proc not available, cannot write pid file!"
else
    SKIFF_INIT_PID_PATH=/mnt/persist/skiff-overlays/skiff-init/skiff-init.pid
    mkdir -p $(dirname ${SKIFF_INIT_PID_PATH}) || true
    # it's important to not use $() here, as it would create a sub-shell.
    cat /host-proc/self/status | grep "PPid:" | awk '{print $2}' > ${SKIFF_INIT_PID_PATH}
    umount /host-proc || true
    rmdir /host-proc || true
fi

# ensure mounts are correct
mount --make-shared /
if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
fi

echo "SkiffOS init: executing systemd inside PID namespace..."
exec /usr/lib/systemd/systemd \
     --log-target=kmsg
