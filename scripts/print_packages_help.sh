#!/bin/bash
# should be run within the configs dir

. ../scripts/utils.sh
. ../scripts/enumerate_configs.sh > /dev/null

# Look through all SKIFF_PACKAGE_ENV_PREFIX variables
IFS=' '
while read -r line; do
  CONFIG_FOUND="yes"
  # line contains THING=value
  varname=$(echo "$line" | cut -d= -f1)
  ppath=$(echo "$line" | cut -d= -f2)
  varnamesuffix=$(echo "$varname" | sed -e "s/^$SKIFF_PACKAGE_ENV_PREFIX//")
  # confpackfull=$(echo "$varname" | rev | cut -d_ -f -3 | rev)
  # packname=$(echo "$confpackfull" | tr '[:upper:]' '[:lower:]' | sed "s#_#/#g")
  varnamen="${SKIFF_PACKAGE_NAME_ENV_PREFIX}${varnamesuffix}"
  packname="${!varnamen}"

  descripp="$ppath/$SKIFF_CONFIG_METADATA_SUBDIR/$SKIFF_CONFIG_METADATA_DESCRIPTION"
  nolist="$ppath/$SKIFF_CONFIG_METADATA_SUBDIR/$SKIFF_CONFIG_METADATA_NOLIST"

  if [ -f "$nolist" ]; then
    continue
  fi

  printf "\033[0;34m$packname\033[0m"
  if [ -f "$descripp" ]; then
    printf ": $(cat $descripp)"
  fi

  echo ""
done <<< "$(env | sort | $SKIFF_FILTER_ENVS)"
if [ -z "$CONFIG_FOUND" ]; then
  echo "No configurations found!"
fi
