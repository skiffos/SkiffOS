#!/bin/bash
set -x

if [ ! -d "$WORKSPACE_DIR" ]; then
  # Setup the worktree
  cd $BUILDROOT_DEFAULT_DIR
  git worktree add --detach "$WORKSPACE_DIR"
  mkdir -p dl/
  ln -s $(pwd)/dl $WORKSPACE_DIR/dl
  cd - > /dev/null
fi
