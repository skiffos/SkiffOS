#!/bin/bash
set -eo pipefail

if [ -z "$WSL_DISTRO_NAME" ]; then
  echo "Not running in WSL."
  exit 1
fi

echo "SkiffOS: inside chroot, executing new PID namespace for systemd..."

export PATH=/usr/lib/systemd:/usr/sbin:/usr/bin

# systemd will mount over /dev/shm
# remove it if it's a file
if [ ! -d /dev/shm ]; then
    rm /dev/shm 2>/dev/null || true
fi
mkdir -p /dev/shm || true
# ensure that proc is mounted
if ! mountpoint -q /proc; then
    mount -t proc proc /proc || true
fi

# to enter ns: chroot /skiff-overlays/system; nsenter -t$(pidof systemd)
set -x
exec unshare --wd=/ --mount --mount-proc \
     --keep-caps --propagation shared \
     --pid --fork --setgroups allow \
     /wsl-systemd.sh
