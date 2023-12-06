#!/bin/bash
set -x

if [ ! -d "$WORKSPACE_DIR" ] || [ ! -f "$WORKSPACE_DIR/Makefile" ]; then
  # Setup the worktree
  cd $BUILDROOT_DEFAULT_DIR
  make O=$WORKSPACE_DIR defconfig || (echo "Buildroot setup failed, check for errors above." && exit 1)
  cd - > /dev/null
fi
if [ ! -d "$SKIFF_WS_OVERRIDES_DIR" ]; then
    mkdir -p $SKIFF_WS_OVERRIDES_DIR
    echo "Place Skiff configuration files for the $SKIFF_WORKSPACE workspace here." > $SKIFF_WS_OVERRIDES_DIR/README
fi

# Ensure that output symbolic links to the same folder.
ln -f -s $WORKSPACE_DIR $WORKSPACE_DIR/output
