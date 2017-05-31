#!/bin/sh
set -e
. ../scripts/utils.sh

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
  REQUIRES_REEVAL=true
  while $REQUIRES_REEVAL; do
    REQUIRES_REEVAL=false
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
        (>&2 echo " ! [$conf] Invalid config, should be category/name. Ignored.")
        continue
      fi
      # Check if its already known
      if containsElement "$conf" "${SKIFF_CONFIGS_FINAL[@]}"; then
        (>&2 echo " ! [$conf] Duplicate, ignoring.")
        continue
      fi
      conf_full=$(echo "$conf" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')
      path_var="${SKIFF_MAGIC_PREFIX}${conf_full}"
      conf_path="${!path_var}"
      if [ -z "$conf_path" ]; then
        (>&2 echo " ! [$conf] Unknown path! $path_var not set. Ignored.")
        continue
      fi
      if [ ! -d "$conf_path" ]; then
        (>&2 echo " ! [$conf] Path $conf_path does not exist. Ignored.")
        continue
      fi
      eval "SKIFF_${conf_full}_COMMAND_LIST=()"
      eval "SKIFF_${conf_full}_COMMAND_PATHS=()"
      # Check if it has any dependencies
      if [ -f "$conf_path/metadata/dependencies" ]; then
        depsuf=$(cat $conf_path/metadata/dependencies)
        if [[ "$depsuf" =~ [^\,\ a-zA-Z0-9/\\] ]]; then
          (>&2 echo " ! [$conf] Invalid dependencies: $depsuf")
          continue
        fi
        invpack=false
        depsn=($(echo "$depsuf" | sed 's/^ *//;s/ *$//' | sed 's/,/ /g' | tr -s " "))
        for depconf in "${depsn[@]}"; do
          # Filter it to make sure it's actually valid
          if [ -z "$(echo $depconf | grep '^[[:alnum:]]\{1,100\}/[[:alnum:]]\{1,100\}$')" ]; then
            echo " ! [$conf] Invalid dependency: $depconf"
            invpack=true
            continue
          fi
          # Make sure we have this in our list of configs
          if ! containsElement "$depconf" "${SKIFF_CONFIGS[@]}"; then
            # Add to the final configs list and respin
            SKIFF_CONFIGS_FINAL+=("$depconf")
            REQUIRES_REEVAL=true
          fi
        done
        if $invpack; then
          continue
        fi
      fi
      # Check if it has a build target override
      if [ -f "$conf_path/metadata/buildtarget" ] && [ -z "$SKIFF_BUILD_TARGET_OVERRIDE" ]; then
        SKIFF_BUILD_TARGET_OVERRIDE="$(cat $conf_path/metadata/buildtarget)"
      fi
      # Check if it has any commands
      if [ -f "$conf_path/metadata/commands" ] && [ -d "$conf_path/extensions" ]; then
        cmdsuf=$(cat $conf_path/metadata/commands)
        cmd_list=()
        cmd_paths=()
        var="$(cat $conf_path/metadata/commands)"
        while read line; do
          # line contains command Description is here
          cmdn=($(echo "$line" | sed 's/^ *//;s/ *$//' | sed 's/,/ /g' | tr -s " "))
          if (( ${#cmdn[@]} < 2 )); then
            continue
          fi
          cmdname="${cmdn[0]}"
          descrip="${cmdn[@]:1}"
          cmdname_full=$(echo "$cmdname" | tr '[:lower:]' '[:upper:]' | sed -e 's#-#_#g')
          export SKIFF_${conf_full}_COMMAND_${cmdname_full}_DESCRIP="$descrip"
          cmd_list+=("$cmdname")
          cmd_paths+=("$conf_path/extensions/")
        done <$conf_path/metadata/commands
        echo ${cmd_list[@]}
        eval "export SKIFF_${conf_full}_COMMAND_LIST=\"${cmd_list[@]}\""
        eval "export SKIFF_${conf_full}_COMMAND_PATHS=\"${cmd_paths[@]}\""
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
    tmp="${SKIFF_COMMAND_LIST[@]}"
    unset SKIFF_COMMAND_LIST
    export SKIFF_COMMAND_LIST="$tmp"
    tmp="${SKIFF_COMMAND_PATH[@]}"
    unset SKIFF_COMMAND_PATH
    export SKIFF_COMMAND_PATH="$tmp"
    if $REQUIRES_REEVAL; then
      echo "Re-evaluating configs due to dep change:"
    fi
  done
fi


# now we have all the env set up
export SKIFF_HAS_ENUMERATED_CONFIGS="yes"
export SKIFF_BUILD_TARGET_OVERRIDE
