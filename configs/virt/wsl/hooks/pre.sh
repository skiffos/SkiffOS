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
