#!/bin/bash

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

path_to_var () {
  partb=$(echo $1 | tr '[:lower:]' '[:upper:]' | sed "s#/#_#")
  echo "${SKIFF_PACKAGE_ENV_PREFIX}${partb}"
}

parts=($(echo "$@" | sed -e "s#/# #g"))
parts=("${parts[@]:1}")
if ! [ "${#parts[@]}" -eq "3" ]; then
  echo "$(tput smso)Invalid command $@!$(tput sgr0)"
  exit 1
fi

conf=${parts[0]}/${parts[1]}
confvn=$(path_to_var "$conf")
if [ -z "${!confvn}" ]; then
  echo "$(tput smso)Package not found $conf!$(tput sgr0)"
  echo $confvn
  exit 1
fi
conf_path="${!confvn}/extensions"
if ! [ -d "${conf_path}" ]; then
  echo "$(tput smso)Can't find $conf_path!$(tput sgr0)"
  exit 1
fi

# Found the config path
source ${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh
export SKIFF_CURRENT_CONF_DIR="${!confvn}"
export SKIFF_CURRENT_CONF_NAME="$conf"
export SKIFF_CURRENT_CONF_NAME_FULL="$confvn"
cd $conf_path && make ${parts[2]}
