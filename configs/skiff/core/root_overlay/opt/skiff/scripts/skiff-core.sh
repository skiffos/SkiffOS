#!/bin/bash
set -eo pipefail

PERSIST_DIR=/mnt/persist
SKIFF_PERSIST_DIR=${PERSIST_DIR}/skiff
CORE_PERSIST_DIR=${SKIFF_PERSIST_DIR}/core
CORE_CONFIG_FILE=${CORE_PERSIST_DIR}/config.yaml
CORE_DEFCONFIG_FILE=/opt/skiff/coreenv/defconfig.yaml

export SKIFF_CORE_WORK_DIR=${CORE_PERSIST_DIR}/tmp
mkdir -p ${SKIFF_CORE_WORK_DIR}
SKIFF_CORE="/usr/bin/skiff-core --config $CORE_CONFIG_FILE"

mkdir -p $CORE_PERSIST_DIR
cd ${CORE_PERSIST_DIR}
if [ ! -f $CORE_CONFIG_FILE ]; then
  if [ -f $CORE_DEFCONFIG_FILE ]; then
    echo "Copying default config from $CORE_DEFCONFIG_FILE to $CORE_CONFIG_FILE"
    cp ${CORE_DEFCONFIG_FILE} ${CORE_CONFIG_FILE}
  else
    echo "Writing default config to $CORE_CONFIG_FILE"
    ${SKIFF_CORE} defconfig
  fi
fi

${SKIFF_CORE} setup --create-users
