#!/bin/bash

TARGET_DIR=$(pwd)/output/target/
TARGET_SCRIPT_DIR=$TARGET_DIR/opt/skiff/scripts
TARGET_COREENV_DIR=$TARGET_DIR/opt/skiff/coreenv
SOURCE_COREENV_DIR=$SKIFF_CORE_ENVIRONMENT
if [ -z "$SOURCE_COREENV_DIR" ]; then
  SOURCE_COREENV_DIR=$SKIFF_CURRENT_CONF_DIR/resources/coreenv
fi
if [ ! -d $SOURCE_COREENV_DIR ]; then
  echo "Unable to find core environment SKIFF_CORE_ENVIRONMENT=$SKIFF_CORE_ENVIRONMENT !"
  exit 1
fi
if [ ! -f $SOURCE_COREENV_DIR/Dockerfile ]; then
  echo "$SOURCE_COREENV_DIR/Dockerfile must exist!"
  exit 1
fi

TARGET_SCRIPT=$TARGET_SCRIPT_DIR/scratchbuild.bash
SOURCE_SCRIPT=$SKIFF_CURRENT_CONF_DIR/resources/scratchbuild/scratchbuild.bash

if [ ! -f $SOURCE_SCRIPT ]; then
  echo "Unable to find $SOURCE_SCRIPT! Maybe run git submodule update --init in skiff tree."
  exit 1
fi

echo "Copying scratchbuild script..."
mkdir -p $TARGET_SCRIPT_DIR
cp $SOURCE_SCRIPT $TARGET_SCRIPT

echo "Copying coreenv files..."
rsync -rav --delete $SOURCE_COREENV_DIR/ $TARGET_COREENV_DIR/
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/Dockerfile >> $TARGET_COREENV_DIR/Dockerfile
cat $SKIFF_CURRENT_CONF_DIR/resources/docker/startup.sh > $TARGET_COREENV_DIR/startup.sh
