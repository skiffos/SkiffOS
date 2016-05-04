#!/bin/bash

pat=$SKIFF_FINAL_CONFIG_DIR/skiff_config
ext=$SKIFF_FINAL_CONFIG_DIR/skiff_extra_configs_path
if [ -d "$SKIFF_FINAL_CONFIG_DIR" ]; then
  if [ -f "$pat" ] && [ -z "$SKIFF_CONFIG" ]; then
    export SKIFF_WARN_ABOUT_RECOVERED_CONFIG=true
    export SKIFF_CONFIG=$(cat $pat)
  fi
  if [ -f "$ext" ] && [ -z "$SKIFF_EXTRA_CONFIGS_PATH" ]; then
    export SKIFF_EXTRA_CONFIGS_PATH=$(cat $ext)
  fi
fi
