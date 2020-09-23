#!/bin/bash

cd $ROOT_DIR

export SKIFF_WORKSPACE=$(echo "$SKIFF_WORKSPACE" | tr -cd '[[:alnum:]]._-' | tr '[:upper:]' '[:lower:]')
if [ -z "$SKIFF_WORKSPACE" ]; then
  export SKIFF_WORKSPACE=default
fi

export SKIFF_FINAL_CONFIG_DIR=$SKIFF_WORKSPACES_DIR/.config_$SKIFF_WORKSPACE/
export SKIFF_WS_OVERRIDES_DIR=$SKIFF_OVERRIDES_DIR/workspaces/$SKIFF_WORKSPACE/
export BR2_CCACHE_DIR=${SKIFF_FINAL_CONFIG_DIR}/br2-ccache
cd - > /dev/null
