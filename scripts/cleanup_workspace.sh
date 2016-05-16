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

# Delete the worktree
if [ "$SKIFF_WORKSPACE" != "default" ] && [ -z "$SKIFF_WORKTREE_NOT_SUPPORTED" ]; then
  cd $BUILDROOT_DEFAULT_DIR
  git worktree prune
  cd - > /dev/null
  rm -rf $WORKSPACE_DIR

# Otherwise just distclean buildroot
else
  cd $WORKSPACE_DIR
  rm .config || true
  make clean
fi

# Delete the config dir
if [ -d "$SKIFF_FINAL_CONFIG_DIR" ]; then
  rm -rf $SKIFF_FINAL_CONFIG_DIR
fi
