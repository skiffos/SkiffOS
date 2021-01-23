#!/bin/bash
set -eo pipefail

if [ -z "$WSL_DISTRO_NAME" ]; then
  echo "Not running in WSL."
  exit 1
fi

echo "SkiffOS: inside chroot, executing new PID namespace for systemd..."

export PATH=/usr/lib/systemd:/usr/sbin:/usr/bin

# to enter ns: chroot /skiff-overlays/system; nsenter -t$(pidof systemd)
set -x
mount --make-shared / || true
exec unshare --wd=/ --mount --mount-proc \
     --keep-caps --propagation shared \
     --pid --fork --setgroups allow \
     /wsl-systemd.sh
