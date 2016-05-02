#!/bin/bash

pat=$SKIFF_FINAL_CONFIG_DIR/skiff_config
if [ -z "$SKIFF_CONFIG" ] && [ -d "$SKIFF_FINAL_CONFIG_DIR" ] && [ -f "$pat" ]; then
  export SKIFF_WARN_ABOUT_RECOVERED_CONFIG=true
  export SKIFF_CONFIG=$(cat $pat)
fi
