#!/bin/bash

pi_config_txt=""
pi_cmdline_txt=""
config_paths=( ${SKIFF_CONFIG_PATH} )
# for (( idx=${#config_paths[@]}-1 ; idx>=0 ; idx-- )) ; do
for confp in "${config_paths[@]}"; do
  conf_i_res="${confp}/resources/rpi"
  if [ -f $conf_i_res/config.txt ]; then
      pi_config_txt="$conf_i_res/config.txt"
  fi
  if [ -f $conf_i_res/cmdline.txt ]; then
      pi_cmdline_txt="$conf_i_res/cmdline.txt"
  fi
done

if [ -z "$pi_config_txt" ]; then
  echo "Unable to find boot command line and config!"
  exit 1
fi

export pi_config_txt
export pi_cmdline_txt
