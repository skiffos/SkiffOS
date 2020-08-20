#!/bin/bash
# should be run within the configs dir

. ../scripts/utils.sh
. ../scripts/enumerate_configs.sh > /dev/null

if [ -z "$BUILDROOT_DEFAULT_DIR" ]; then
    echo "BUILDROOT_DEFAULT_DIR is not set, was primary_env sourced?"
    exit 1
fi

# Look through all SKIFF_PACKAGE_ENV_PREFIX variables
IFS=' '
while read -r line; do
  CONFIG_FOUND="yes"
  # line contains THING=value
  varname=$(echo "$line" | cut -d= -f1)
  ppath=$(echo "$line" | cut -d= -f2)
  confpackfull=$(echo "$varname" | rev | cut -d_ -f -2 | rev)
  packname=$(echo "$confpackfull" | tr '[:upper:]' '[:lower:]' | sed "s#_#/#g")

  brext="$ppath/buildroot_ext"
  if [ ! -d "$brext" ]; then
    continue
  fi

	echo "$(tput smso)${packname}$(tput sgr0)"
  python3 ${BUILDROOT_DEFAULT_DIR}/utils/check-package -b $brext/*

  echo ""
done <<< "$(env | sort | $SKIFF_FILTER_ENVS)"

if [ -z "$CONFIG_FOUND" ]; then
  echo "No configurations with buildroot_ext found (should be at least one)!"
  exit 1
fi
