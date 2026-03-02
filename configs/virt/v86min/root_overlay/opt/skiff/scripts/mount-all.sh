#!/bin/bash
# v86min: minimal init for ramdisk-only browser environment.
# Overrides the full SkiffOS mount-all.sh.

# No persist partition, no block devices, no SSH, no NetworkManager.
# Just set hostname and machine-id.

hostname -F /etc/hostname 2>/dev/null || true
systemd-machine-id-setup --print --commit >/dev/null 2>&1 || true
