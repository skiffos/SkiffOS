#!/bin/bash
set -eo pipefail

errecho() {
  (>&2 echo $1)
}

# Assume we are in configs dir
if [ -z "$SKIFF_HAS_ENUMERATED_CONFIGS" ]; then
  . ../scripts/enumerate_configs.sh
fi

if [ -z "$SKIFF_CONFIG" ]; then
  errecho "Set SKIFF_CONFIG, for example: odroid/xu4,apps/docker"
  exit 1
fi
