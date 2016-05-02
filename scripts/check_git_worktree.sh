#!/bin/bash

cd $ROOT_DIR
if ! git worktree list > /dev/null 2>&1; then
  export SKIFF_WORKTREE_NOT_SUPPORTED=true
  if [ -n "$SKIFF_WORKSPACE" ]; then
    export SKIFF_WORKSPACE_IGNORED=true
    export SKIFF_WORKSPACE=default
  fi
fi

export SKIFF_WORKSPACE=$(echo "$SKIFF_WORKSPACE" | tr -cd '[[:alnum:]]._-' | tr '[:upper:]' '[:lower:]')
if [ -z "$SKIFF_WORKSPACE" ]; then
  export SKIFF_WORKSPACE=default
fi

export SKIFF_FINAL_CONFIG_DIR=$ROOT_DIR/workspaces/.config_$SKIFF_WORKSPACE/
cd - > /dev/null
