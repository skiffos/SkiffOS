#!/bin/bash

cd ../configs && . ../scripts/enumerate_configs.sh >/dev/null && cd - > /dev/null

echo -e "\e[7;49;31m"
cat ../resources/text/logo.ascii
echo -e "\e[0m"

echo ""
if [ -n "$SKIFF_WORKTREE_NOT_SUPPORTED" ]; then
  printf "\033[1;49;31m✖ Your git does not support worktree. SKIFF_WORKSPACE ignored.\033[0m\n"
fi
printf "\033[0;34m✓ SKIFF_WORKSPACE is: $SKIFF_WORKSPACE\033[0m\n"
if [ -n "$SKIFF_WARN_ABOUT_RECOVERED_CONFIG" ]; then
  printf "\033[0;34m✓ Previous config recovered: $SKIFF_CONFIG\033[0m\n"
fi
if ERR=$(../scripts/verify_selected_config.sh 2>&1); then
  printf "\033[0;34m✓ Selected config chain:\033[0m\n"
  i=0
  for conf in "${SKIFF_CONFIGS[@]}"; do
    conf_path=${SKIFF_CONFIG_PATH[i]}
    path_to_descrip="$conf_path/$SKIFF_CONFIG_METADATA_SUBDIR/$SKIFF_CONFIG_METADATA_DESCRIPTION"
    printf "  $conf"
    if [ -f "$path_to_descrip" ]; then
      printf ": $(cat $path_to_descrip)\n"
    else
      printf "\n"
    fi
    i+=1
  done
else
  printf "\033[1;49;31m✖ $ERR\033[0m\n"
fi

echo ""
echo -e "\e[0;31m\033[1mConfigurations\e[0m"
echo -e "Set SKIFF_CONFIG to one or more of the following (comma separated):"
cd ../configs/ && ../scripts/print_packages_help.sh
cd - > /dev/null
echo ""

echo -e "\e[0;31m\033[1mCommands\e[0m"
echo -e "\033[0;34mcompile\033[0m:   Configures and compiles the system."
echo -e "\033[0;34mconfigure\033[0m: Force a re-configuration of the system."
echo -e "\033[0;34mclean\033[0m:     Cleans the current workspace."

# Iterate over configs in config chain and print available commands
