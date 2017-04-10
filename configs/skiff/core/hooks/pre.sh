#!/bin/bash

TARGET_DIR=$(pwd)/target/
TARGET_SCRIPT_DIR=$TARGET_DIR/opt/skiff/scripts
TARGET_COREENV_DIR=$TARGET_DIR/opt/skiff/coreenv

TARGET_SCRIPT=$TARGET_SCRIPT_DIR/scratchbuild.bash
SOURCE_SCRIPT=$SKIFF_CURRENT_CONF_DIR/resources/scratchbuild/scratchbuild.bash

if [ ! -f $SOURCE_SCRIPT ]; then
  echo "Unable to find $SOURCE_SCRIPT! Maybe run git submodule update --init in skiff tree."
  exit 1
fi

echo "Copying scratchbuild script..."
mkdir -p $TARGET_SCRIPT_DIR
cp $SOURCE_SCRIPT $TARGET_SCRIPT

echo "Copying coreenv base..."
mkdir -p $TARGET_COREENV_DIR/base/
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/Dockerfile > $TARGET_COREENV_DIR/base/Dockerfile
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/startup.sh > $TARGET_COREENV_DIR/base/startup.sh
