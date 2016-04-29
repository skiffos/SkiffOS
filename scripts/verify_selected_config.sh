#!/bin/bash
errecho() {
  (>&2 echo $1)
}

# Assume we are in configs dir
if [ -z "$SKIFF_HAS_ENUMERATED_CONFIGS" ]; then
  source ../scripts/enumerate_configs.sh
fi

if [ -z "$SKIFF_CONFIG" ]; then
  errecho "Set SKIFF_CONFIG."
  exit 1
fi

if [ -z "$SKIFF_CONFIG_PATH" ]; then
  errecho "Config path not found for $SKIFF_CONFIG."
  exit 1
fi

if [ ! -d "$SKIFF_CONFIG_PATH" ]; then
  errecho "Cannot find directory $SKIFF_CONFIG_PATH."
  exit 1
fi
