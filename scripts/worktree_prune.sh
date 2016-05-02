#!/bin/bash

if [ -z "$SKIFF_WORKTREE_NOT_SUPPORTED" ]; then
  cd $BUILDROOT_DEFAULT_DIR
  git worktree prune
  cd - > /dev/null
fi
