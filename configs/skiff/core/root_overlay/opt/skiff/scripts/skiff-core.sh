#!/bin/bash
set -eo pipefail

PERSIST_DIR=/mnt/persist
SKIFF_PERSIST_DIR=${PERSIST_DIR}/skiff
CORE_PERSIST_DIR=${SKIFF_PERSIST_DIR}/core
CORE_CONFIG_FILE=${CORE_PERSIST_DIR}/config.yaml

SKIFF_CORE="/usr/bin/skiff-core --config $CORE_CONFIG_FILE"

mkdir -p $CORE_PERSIST_DIR
if [ ! -f $CORE_CONFIG_FILE ]; then
  echo "Writing default config to $CORE_CONFIG_FILE"
  ${SKIFF_CORE} defconfig
fi

${SKIFF_CORE} setup --create-users
