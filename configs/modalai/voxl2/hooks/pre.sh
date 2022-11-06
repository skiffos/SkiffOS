#!/bin/bash
set -eo pipefail

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/target

# Create firmware mountpoint.
mkdir -p ${TARGET_DIR}/firmware
