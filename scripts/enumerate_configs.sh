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
        echo "> [$pack] [$conffp]"
        export ${confvarn}="$conffp"
      else
        echo "! [$pack] [$iter] (duplicate, ignored)"
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

# now we have all the env set up
# env | grep "${SKIFF_MAGIC_PREFIX}.*="
