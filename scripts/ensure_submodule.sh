#!/bin/bash
set -e

cd $ROOT_DIR
if [ ! -d "./buildroot" ] || [ ! -f "./buildroot/Makefile" ]; then
  git submodule update --init --recursive # --progress
fi
