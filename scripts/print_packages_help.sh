#!/bin/bash
# should be run within the configs dir

source ../scripts/utils.sh
source ../scripts/enumerate_configs.sh > /dev/null

# Look through all SKIFF_PACKAGE_ENV_PREFIX variables
IFS=' '
while read -r line; do
  CONFIG_FOUND="yes"
  # line contains THING=value
  varname=$(echo "$line" | cut -d= -f1)
  ppath=$(echo "$line" | cut -d= -f2)
  confpackfull=$(echo "$varname" | rev | cut -d_ -f -2 | rev)
  packname=$(echo "$confpackfull" | tr '[:upper:]' '[:lower:]' | sed "s#_#/#g")

  descripp="$ppath/$SKIFF_CONFIG_METADATA_SUBDIR/$SKIFF_CONFIG_METADATA_DESCRIPTION"

  printf "\033[0;34m$packname\033[0m"
  if [ -f "$descripp" ]; then
    printf ": $(cat $descripp)"
  fi

  echo ""
done <<< "$(env | $SKIFF_FILTER_ENVS)"
if [ -z "$CONFIG_FOUND" ]; then
  echo "No configurations found!"
fi
