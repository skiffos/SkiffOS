#!/bin/bash

cd $ROOT_DIR

export SKIFF_WORKSPACE=$(echo "$SKIFF_WORKSPACE" | tr -cd '[[:alnum:]]._-' | tr '[:upper:]' '[:lower:]')
if [ -z "$SKIFF_WORKSPACE" ]; then
  export SKIFF_WORKSPACE=default
fi

export SKIFF_FINAL_CONFIG_DIR=$ROOT_DIR/workspaces/.config_$SKIFF_WORKSPACE/
cd - > /dev/null
