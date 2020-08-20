#!/bin/bash

source ../scripts/utils.sh
echo -e "\e[7;49;31m"
cat ../resources/text/logo.ascii
echo -e "\e[0m"

printf "\033[0;32mWelcome to SkiffOS ${SKIFF_VERSION}!\033[0m\n"
echo ""
printf "\033[0;34m ✓ SKIFF_WORKSPACE is: $SKIFF_WORKSPACE\033[0m\n"
if [ -n "$SKIFF_WARN_ABOUT_RECOVERED_CONFIG" ]; then
  printf "\033[0;34m ✓ Previous config recovered\033[0m\n"
fi
if ERR=$(../scripts/verify_selected_config.sh 2>&1); then
  printf "\033[0;34m ✓ Selected config chain:\033[0m\n"
  ci=0
  for conf in "${SKIFF_CONFIGS[@]}"; do
    conf_path=${SKIFF_CONFIG_PATH[ci]}
    ci=$(($ci + 1))
    path_to_descrip="${conf_path}/${SKIFF_CONFIG_METADATA_SUBDIR}/${SKIFF_CONFIG_METADATA_DESCRIPTION}"
    # printf "     \033[0;34m$conf\033[0m"
    printf "     "
    descrip=""
    if [ -f "$path_to_descrip" ]; then
        descrip=$(cat $path_to_descrip)
    fi
    printf '\e[107m\033[0;45m%s\033[0m\e[49m\t %s\n' "$conf" "$descrip" | expand -t 22
  done
else
  printf "\033[1;49;31m✖ $ERR\033[0m\n"
fi

echo
echo -e "\e[0;31m\033[1mConfigurations\e[0m"
echo -e "Set SKIFF_CONFIG to one or more of the following (comma separated):"
cd ../configs/ && ../scripts/print_packages_help.sh
cd - > /dev/null
echo

echo -e "\e[0;31m\033[1mBuild Commands\e[0m"
echo -e "\033[0;34mconfigure\033[0m:  Force a re-configuration of the system."
echo -e "\033[0;34mcompile\033[0m:    Configures and compiles the system."
echo -e "\033[0;34mclean\033[0m:      Cleans the current workspace."
echo

echo -e "\e[0;31m\033[1mUtility Commands\e[0m"
echo -e "\033[0;34mcheck\033[0m:      Configures and checks the current workspace."
echo -e "\033[0;34mgraph\033[0m:      Graph the completed build timing."
echo -e "\033[0;34mlegal-info\033[0m: Legal information."
echo -e "\033[0;34mbr/*\033[0m:       Execute a buildroot command, ex: br/menuconfig."

# Iterate over configs in config chain and print available commands
i=0
confs=( ${SKIFF_CONFIGS[@]} )
for conf in "${confs[@]}"; do
  conf_full=$(echo "$conf" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')
  cmd_full_cmdlv="SKIFF_${conf_full}_COMMAND_LIST"
  cmd_full_cmdpt="SKIFF_${conf_full}_COMMAND_PATHS"
  if [ -z "${!cmd_full_cmdlv}" ]; then
    continue
  fi

  cmd_full_cmdl=${!cmd_full_cmdlv}
  cmd_cmdl=( $cmd_full_cmdl )
  cmd_full_cmdp=( ${!cmd_full_cmdpt} )

  # Print command header
  echo ""
  echo -e "\e[0;31m\033[1m${conf} Commands\e[0m"
  for cmd in "${cmd_cmdl[@]}"; do
    cmd_full=$(echo "$cmd" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')
    descripnv="SKIFF_${conf_full}_COMMAND_${cmd_full}_DESCRIP"
    descrip=${!descripnv}
    echo -e "\033[0;34mcmd/$conf/$cmd\033[0m: $descrip"
  done

  i+=1
done
