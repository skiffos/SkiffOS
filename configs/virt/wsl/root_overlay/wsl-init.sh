#!/bin/bash
set -eo pipefail

if [ -z "$WSL_DISTRO_NAME" ]; then
  echo "Not running in WSL."
  exit 1
fi

echo "SkiffOS: inside chroot, executing new PID namespace for systemd..."

WSL_WINDOWS_PATH_DIR=/mnt/persist/skiff-overlays/skiff-init
WSL_WINDOWS_PATH_FILE=${WSL_WINDOWS_PATH_DIR}/wsl-windows-path
if mkdir -p "${WSL_WINDOWS_PATH_DIR}" 2>/dev/null; then
  : > "${WSL_WINDOWS_PATH_FILE}" || true
  if [ -w "${WSL_WINDOWS_PATH_FILE}" ]; then
    old_ifs=${IFS}
    IFS=:
    for wsl_path_dir in ${PATH}; do
      case "${wsl_path_dir}" in
        /mnt/[A-Za-z]/*)
          printf '%s\n' "${wsl_path_dir}" >> "${WSL_WINDOWS_PATH_FILE}"
          ;;
      esac
    done
    IFS=${old_ifs}
    unset old_ifs wsl_path_dir
  fi
fi
unset WSL_WINDOWS_PATH_DIR WSL_WINDOWS_PATH_FILE

export PATH=/usr/lib/systemd:/usr/sbin:/usr/bin

# ensure that / is shared
mount --make-shared /

# systemd will mount over /dev/shm
# remove it if it's a file
if [ ! -d /dev/shm ]; then
    rm /dev/shm 2>/dev/null || true
fi
mkdir -p /dev/shm || true

# ensure that the host proc is mounted, so unshare can use it
if mountpoint -q /proc; then
  umount /proc || true
fi
mount -t proc proc /proc

# bind /proc to /host-proc so we can determine the PID in host namespace
if [ ! -d /host-proc ] || ! mountpoint -q /host-proc; then
    mkdir -p /host-proc || true
    mount -t proc proc /host-proc
fi

# to enter ns: chroot /skiff-overlays/system; nsenter -t$(pidof systemd)
set -x
exec unshare --wd=/ --mount --mount-proc \
     --keep-caps --propagation shared \
     --pid --fork --setgroups allow \
     /wsl-systemd.sh
