#!/bin/bash

pi_config_txt=""
pi_cmdline_txt=""
config_paths=( ${SKIFF_CONFIG_PATH} )
for (( idx=${#config_paths[@]}-1 ; idx>=0 ; idx-- )) ; do
  conf_i_res="${config_paths[idx]}/resources/rpi"
  if [ ! -d $conf_i_res ]; then
    continue
  fi
  pi_config_txt="$conf_i_res/config.txt"
  pi_cmdline_txt="$conf_i_res/cmdline.txt"
done

if [ -z "$pi_config_txt" ]; then
  echo "Unable to find boot command line and config!"
  exit 1
fi

export pi_config_txt
export pi_cmdline_txt
