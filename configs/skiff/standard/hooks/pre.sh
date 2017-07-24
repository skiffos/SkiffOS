#!/bin/bash

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/output/target
SYSTEMD_DIR=${TARGET_DIR}/usr/lib/systemd/system

mkdir -p ${SKIFF_BUILDROOT_DIR}/output/images/resources
rm ${SYSTEMD_DIR}/network-online.target.wants/NetworkManager-wait-online.service || true
mkdir -p ${SYSTEMD_DIR}/basic.target.wants
if [ -f ${SYSTEMD_DIR}/sysinit.target.wants/systemd-journald.service ]; then
    mv ${SYSTEMD_DIR}/sysinit.target.wants/systemd-journal* ${SYSTEMD_DIR}/basic.target.wants/ || true
fi
rm ${SKIFF_BUILDROOT_DIR}/output/target/etc/resolv.conf || true
echo "# Managed by NetworkManager" > ${SKIFF_BUILDROOT_DIR}/output/target/etc/resolv.conf

mkdir -p ${TARGET_DIR}/etc
( \
  echo "NAME=SkiffOS"; \
  echo "VERSION=${SKIFF_VERSION}"; \
  echo "ID=skiff"; \
  echo "VERSION_ID=${SKIFF_VERSION_COMMIT}"; \
  echo "PRETTY_NAME=\"SkiffOS ${SKIFF_VERSION}\""; \
  echo "BUILD_DATE=\"$(date)\""; \
  echo "BUILD_USER=\"${USER}@$(hostname)\""; \
  echo "VERSION_FULL=\"SkiffOS version ${SKIFF_VERSION} (${USER}@$(hostname)) $(date)"; \
) > ${TARGET_DIR}/etc/skiff-release
