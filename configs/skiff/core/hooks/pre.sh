#!/bin/bash

TARGET_DIR=${SKIFF_BUILDROOT_DIR}/output/target/
TARGET_COREENV_DIR=$TARGET_DIR/opt/skiff/coreenv

echo "Copying coreenv base..."
mkdir -p $TARGET_COREENV_DIR/base/
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/Dockerfile > $TARGET_COREENV_DIR/base/Dockerfile
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/startup.sh > $TARGET_COREENV_DIR/base/startup.sh
