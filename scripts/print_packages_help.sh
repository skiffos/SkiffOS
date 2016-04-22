#!/bin/bash
# should be run within the configs dir

source ../scripts/enumerate_configs.sh > /dev/null

# Look through all SKIFF_PACKAGE_ENV_PREFIX variables
while read -r line; do
  # line contains THING=value
  return
done <<< "$(env | grep $SKIFF_PACKAGE_ENV_PREFIX.*=)"
