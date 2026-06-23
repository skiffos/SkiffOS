#!/bin/bash
set -eo pipefail

container=${SKIFF_DBUS_PROXY_CONTAINER:-core}
host_bus=${SKIFF_DBUS_PROXY_HOST_BUS:-unix:path=/run/dbus/system_bus_socket}
services=${SKIFF_DBUS_PROXY_SERVICES:-org.freedesktop.NetworkManager}
timeout=${SKIFF_DBUS_PROXY_WAIT_SECONDS:-120}

deadline=$((SECONDS + timeout))

wait_for_container_pid() {
  local pid
  while [ "$SECONDS" -lt "$deadline" ]; do
    pid=$(docker inspect -f '{{.State.Pid}}' "$container" 2>/dev/null || true)
    if [ -n "$pid" ] && [ "$pid" != "0" ]; then
      printf '%s\n' "$pid"
      return 0
    fi
    sleep 1
  done
  return 1
}

wait_for_container_bus() {
  local pid=$1
  local bus=/proc/${pid}/root/run/dbus/system_bus_socket
  while [ "$SECONDS" -lt "$deadline" ]; do
    if [ -S "$bus" ]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

pid=$(wait_for_container_pid) || {
  echo "skiff-dbus-proxy: timed out waiting for container $container" >&2
  exit 1
}

wait_for_container_bus "$pid" || {
  echo "skiff-dbus-proxy: timed out waiting for $container system bus" >&2
  exit 1
}

args=(--from "$host_bus" --container-pid "$pid")
for service in $services; do
  args+=(--service "$service")
done

exec /usr/bin/skiff-dbus-proxy "${args[@]}"
