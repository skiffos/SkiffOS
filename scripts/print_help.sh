#!/bin/bash

cd ../configs && . ../scripts/enumerate_configs.sh >/dev/null && cd - > /dev/null

echo -e "\e[7;49;31m"
cat ../resources/text/logo.ascii
echo -e "\e[0m"

if [ -n "$SKIFF_CONFIG" ]; then
  echo ""
  if ERR=$(../scripts/verify_selected_config.sh 2>&1); then
    printf "\033[0;34m✓ Selected config:\033[0m $SKIFF_CONFIG\n"
  else
    printf "\033[1;49;31m✖ $ERR\033[0m\n"
  fi
fi

echo ""
echo -e "\e[0;31m\033[1mConfigurations\e[0m"
echo -e "Set SKIFF_CONFIG to one of the following:"
cd ../configs/ && ../scripts/print_packages_help.sh
cd - > /dev/null
echo ""

echo -e "\e[0;31m\033[1mCommands\e[0m"
echo -e "\033[0;34mbuild\033[0m: Compiles the system."
