#!/bin/bash

config_paths=($SKIFF_CONFIG_PATH)
for ((idx = ${#config_paths[@]} - 1; idx >= 0; idx--)); do
  conf_i_res=${config_paths[idx]}/resources/boot-scripts
  if [ ! -d "$conf_i_res" ]; then
    continue
  fi

  boot_cmd=$conf_i_res/boot.cmd
  if [ -f "$boot_cmd" ]; then
    echo "Using boot.cmd at $boot_cmd"
    boot_conf=$boot_cmd
    break
  fi
done

if [ -z "$boot_conf" ]; then
  echo "Unable to find boot script!"
  exit 1
fi
