#!/bin/bash

refind_config=""
config_paths=( ${SKIFF_CONFIG_PATH} )
# for (( idx=${#config_paths[@]}-1 ; idx>=0 ; idx-- )) ; do
for confp in "${config_paths[@]}"; do
  conf_i_res="${confp}/resources"
  if [ -f $conf_i_res/refind_linux.conf ]; then
      refind_config="$conf_i_res/refind_linux.conf"
  fi
done

if [ -z "$refind_config" ]; then
  echo "Unable to find refind_linux.conf!"
  exit 1
fi

export refind_config
