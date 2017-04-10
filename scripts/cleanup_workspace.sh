#!/bin/bash
set -e

if [ ! -d $WORKSPACE_DIR ]; then
  exit 0
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will clean and delete your current workspace. [y/N] " -n 1 -r
  echo    # (optional) move to a new line
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [ "$SKIFF_WORKSPACE" != "default" ] ; then
  rm -rf $WORKSPACE_DIR
else
  cd $WORKSPACE_DIR
  rm .config || true
  make clean
fi

# Delete the config dir
if [ -d "$SKIFF_FINAL_CONFIG_DIR" ]; then
  rm -rf $SKIFF_FINAL_CONFIG_DIR
fi
