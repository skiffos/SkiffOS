#!/bin/sh
set -e
source ../scripts/utils.sh

echo -e "Discovered Skiff configs:"

# Disable output from pushd/popd
pushd () {
  command pushd "$@" > /dev/null
}
popd () {
  command popd "$@" > /dev/null
}
function joinStr { local IFS="$1"; shift; echo "$*"; }
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

SKIFF_MAGIC_PREFIX="${SKIFF_PACKAGE_ENV_PREFIX}"

# Converts odroid/xu4 to SKIFF_CONFIG_PATH_ODROID_XU4
path_to_var () {
  partb=$(echo $1 | tr '[:lower:]' '[:upper:]' | sed "s#/#_#")
  echo "${SKIFF_MAGIC_PREFIX}${partb}"
}

SKIFF_CONFIGS_PATH="$(pwd)"
if [ -n "$SKIFF_EXTRA_CONFIGS_PATH" ]; then
  SKIFF_CONFIGS_PATH="${SKIFF_EXTRA_CONFIGS_PATH}:${SKIFF_CONFIGS_PATH}"
fi

# For each config path, list the packages and build SKIFF_CONFIG_PATH_... variables
skiff_packvars=()
var="$SKIFF_CONFIGS_PATH"
while [ "$var" ] ;do
  iter=${var%%:*}

  #iter contains the path
  #echo "> [$iter]"

  #packages will contain odroid/xu4\nodroid\xu3
  pushd $iter
  # packages=$(find . -mindepth 2 -maxdepth 2 -type d | sed -e 's#.\{2\}##' | tr '\n' ':')
  packages=$(find . -mindepth 2 -maxdepth 2 -type d | sed -n 's#[^/]*/##p' | tr '\n' ':')
  popd

  # iterate over packages
  while [ "$packages" ] ;do
    pack=${packages%%:*}
    # Pack contains odroid/xu4
    # First check for invalid chars
    if [[ "$pack" =~ [^a-zA-Z0-9/\\] ]]; then
      echo "! [$pack] (ignored, invalid characters)"
    else
      # convert it to a var
      confvarn=$(path_to_var "$pack")

      # confvarn contains SKIFF_CONFIG_PATH_ODROID_XU4
      # set it if not already set
      # this way the precedence is:
      # - preset SKIFF_CONFIG_PATH_ODROID_XU4
      # - path from EXTRA_CONFIGS_PATH
      # - built in odroid/xu4
      conffp="${iter}/${pack}"
      conffp=$(echo "$conffp" | sed -e "s#//#/#g")
      if [ -z "${!confvarn}" ]; then
        echo " > [$pack] [$conffp]"
        export ${confvarn}="$conffp"
      else
        echo " ! [$pack] [$iter] (duplicate, ignored)"
      fi
    fi

    [ "$packages" = "$pack" ] && \
      packages='' || \
      packages="${packages#*:}"
  done

  [ "$var" = "$iter" ] && \
    var='' || \
    var="${var#*:}"
done

# Now see if we can find SKIFF_CONFIG.
# SKIFF_CONFIG_FULL = ODROID_XU4
if [ -n "$SKIFF_CONFIG" ]; then
  echo "Selected config chain (from SKIFF_CONFIG):"
  # Split SKIFF_CONFIG into configs, by converting comma to space
  export SKIFF_CONFIG=$(echo "$SKIFF_CONFIG" | sed 's/^ *//;s/ *$//' | sed 's/,/ /g' | tr -s " ")
  # Iterate over it
  SKIFF_CONFIGS=($SKIFF_CONFIG)
  SKIFF_CONFIG_FULL=()
  SKIFF_CONFIG_PATH_VAR=()
  SKIFF_CONFIG_PATH=()
  SKIFF_CONFIGS_FINAL=()
  for conf in "${SKIFF_CONFIGS[@]}"; do
    # Filter it to make sure it's actually valid
    if [ -z "$(echo $conf | grep '^[[:alnum:]]\{1,100\}/[[:alnum:]]\{1,100\}$')" ]; then
      echo " ! [$conf] Invalid config, should be category/name. Ignored."
      continue
    fi
    # Check if its already known
    if containsElement "$conf" "${SKIFF_CONFIGS_FINAL[@]}"; then
      echo " ! [$conf] Duplicate, ignoring."
      continue
    fi
    conf_full=$(echo "$conf" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')
    path_var="${SKIFF_MAGIC_PREFIX}${conf_full}"
    conf_path="${!path_var}"
    if [ -z "$conf_path" ]; then
      echo " ! [$conf] Unknown path! $path_var not set. Ignored."
      continue
    fi
    if [ ! -d "$conf_path" ]; then
      echo " ! [$conf] Path $conf_path does not exist. Ignored."
      continue
    fi
    SKIFF_CONFIG_FULL+=("$conf_full")
    SKIFF_CONFIG_PATH_VAR+=("$path_var")
    SKIFF_CONFIG_PATH+=("$conf_path")
    SKIFF_CONFIGS_FINAL+=("$conf")
    echo " > [$conf] [$conf_path]"
  done
  unset SKIFF_CONFIGS
  export SKIFF_CONFIGS="${SKIFF_CONFIGS_FINAL[@]}"
  tmp="${SKIFF_CONFIG_FULL[@]}"
  unset SKIFF_CONFIG_FULL
  export SKIFF_CONFIG_FULL="$tmp"
  tmp="${SKIFF_CONFIG_PATH_VAR[@]}"
  unset SKIFF_CONFIG_PATH_VAR
  export SKIFF_CONFIG_PATH_VAR="$tmp"
  tmp="${SKIFF_CONFIG_PATH[@]}"
  unset SKIFF_CONFIG_PATH
  export SKIFF_CONFIG_PATH="$tmp"
  export SKIFF_CONFIG=$(joinStr , ${SKIFF_CONFIGS[@]})
fi


# now we have all the env set up
export SKIFF_HAS_ENUMERATED_CONFIGS="yes"
