#!/bin/bash

# Build config like this:
# - configs/base
# - alphabetical: SKIFF_CONFIG_PATH/buildroot/config
# Merge them together, tell buildroot to use it as a defconfig

SKIFF_BRCONF_WORK_DIR=$(mktemp -d)
SKIFF_BRCONF_PATH=${SKIFF_CONFIG_PATH}/buildroot/config

function cleanup {
  rm -rf "$SKIFF_BRCONF_WORK_DIR"
}
trap cleanup EXIT

cp ${SKIFF_CONFIGS_DIR}/base/buildroot $SKIFF_BRCONF_WORK_DIR/000_base_a

if [ -d $SKIFF_BRCONF_PATH ]; then
  # List files in alphabetical order in the path
  for file in `ls -v $SKIFF_BRCONF_PATH`; do echo $i; done;
fi
