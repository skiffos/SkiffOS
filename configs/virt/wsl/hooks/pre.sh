#!/bin/bash

echo "virt/wsl: removing some systemd targets..."
TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target
find ${TARGET_DIR}/etc/systemd/system \
     ${TARGET_DIR}/lib/systemd/system \
     \( -path '*.wants/*' \
     -name '*swapon*' \
     -or -name 'systemd-binfmt.service' \
     -or -name 'systemd-timesyncd.service' \
     -or -name 'systemd-modules-load.service' \
     -or -name 'wpa_supplicant.service' \
     -or -name 'rdisc.service' \
     -or -name 'systemd-remount-fs.service' \) \
     -exec echo \{\} \; \
     -exec rm \{\} \;

echo "virt/wsl: creating wsl-shell symlink in target..."
if [ -f ${TARGET_DIR}/bin/wsl-shell ]; then
    rm ${TARGET_DIR}/bin/wsl-shell || true
fi
ln -fs /bin/bash ${TARGET_DIR}/bin/wsl-shell
