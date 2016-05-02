#!/bin/bash
set -e

cd $ROOT_DIR
if [ ! -d "./workspaces/default" ] || [ ! -f "./workspaces/default/Makefile" ]; then
  git submodule update --init --recursive
fi
