#!/bin/bash

# Runs cmd/<category>/<name>/<command> from the extensions Makefile of the
# first config that defines the command, searching the named config and then
# its metadata/dependencies breadth first. A board config can therefore run the
# commands of the common config it depends on, such as cmd/bananapi/m3/format.

path_to_var() {
  echo "${SKIFF_PACKAGE_ENV_PREFIX}$(echo "$1" | tr '[:lower:]' '[:upper:]' | sed 's#/#_#g')"
}

# has_command succeeds if the config at path $1 defines the make target $2.
has_command() {
  [ -f "$1/extensions/Makefile" ] &&
    make -s -n -C "$1/extensions" "$2" >/dev/null 2>&1
}

fail() {
  echo "$(tput smso)$1$(tput sgr0)"
  exit 1
}

parts=($(echo "$1" | sed 's#/# #g'))
if [ "${#parts[@]}" -ne 4 ]; then
  fail "Invalid command $1, expected cmd/<category>/<name>/<command>!"
fi
conf="${parts[1]}/${parts[2]}"
cmd="${parts[3]}"

declare -A seen
queue=("$conf")
found=""
while [ "${#queue[@]}" -gt 0 ]; do
  cur="${queue[0]}"
  queue=("${queue[@]:1}")
  if [ -n "${seen[$cur]}" ]; then
    continue
  fi
  seen[$cur]=1

  cur_var=$(path_to_var "$cur")
  cur_path="${!cur_var}"
  if [ -z "$cur_path" ]; then
    fail "Config not found: $cur!"
  fi
  if has_command "$cur_path" "$cmd"; then
    found="$cur"
    break
  fi
  if [ -f "$cur_path/metadata/dependencies" ]; then
    queue+=($(sed 's/,/ /g' "$cur_path/metadata/dependencies"))
  fi
done

if [ -z "$found" ]; then
  fail "No command $cmd in $conf or its dependencies!"
fi
if [ "$found" != "$conf" ]; then
  echo "Running cmd/$found/$cmd"
fi

found_var=$(path_to_var "$found")
source "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"
export SKIFF_CURRENT_CONF_DIR="${!found_var}"
export SKIFF_CURRENT_CONF_NAME="$found"
export SKIFF_CURRENT_CONF_NAME_FULL="$found_var"
cd "${SKIFF_CURRENT_CONF_DIR}/extensions" && make "$cmd"
