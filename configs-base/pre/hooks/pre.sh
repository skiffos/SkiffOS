#!/bin/bash

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/output/target

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

