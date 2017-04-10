#!/bin/bash
set -x

if [ ! -d "$WORKSPACE_DIR" ]; then
  # Setup the worktree
  cd $BUILDROOT_DEFAULT_DIR
  make O=$WORKSPACE_DIR defconfig
  ln -f -s $WORKSPACE_DIR $WORKSPACE_DIR/output
  cd - > /dev/null
fi
