#!/bin/bash

set -u

STATUS_OUTPUT=${SKIFF_STATUS_OUTPUT:-/dev/tty1}
WAIT_SECONDS=${SKIFF_STATUS_WAIT_SECONDS:-15}

if [ ! -e "$STATUS_OUTPUT" ]; then
    exit 0
fi

wait_for_network() {
    if [ "$WAIT_SECONDS" = "0" ]; then
        return
    fi

    if command -v nm-online >/dev/null 2>&1; then
        nm-online -q -t "$WAIT_SECONDS" >/dev/null 2>&1 || true
    fi
}

hostname_text() {
    hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || printf 'skiffos\n'
}

ipv4_addresses() {
    if command -v ip >/dev/null 2>&1; then
        ip -o -4 addr show scope global 2>/dev/null | while read -r _ iface _ addr _; do
            printf '  %s %s\n' "$iface" "${addr%%/*}"
        done
        return
    fi

    if command -v hostname >/dev/null 2>&1; then
        for addr in $(hostname -I 2>/dev/null); do
            case "$addr" in
                *:*) ;;
                *) printf '  %s\n' "$addr" ;;
            esac
        done
    fi
}

service_state() {
    unit=$1

    if ! command -v systemctl >/dev/null 2>&1; then
        printf '  %-24s systemctl unavailable\n' "$unit"
        return
    fi

    load=$(systemctl show -p LoadState --value "$unit" 2>/dev/null || true)
    if [ -z "$load" ] || [ "$load" = "not-found" ]; then
        printf '  %-24s not installed\n' "$unit"
        return
    fi

    active=$(systemctl show -p ActiveState --value "$unit" 2>/dev/null || true)
    sub=$(systemctl show -p SubState --value "$unit" 2>/dev/null || true)

    if [ -z "$active" ]; then
        active=unknown
    fi
    if [ -z "$sub" ]; then
        sub=unknown
    fi

    case "$load" in
        loaded)
            printf '  %-24s %s/%s\n' "$unit" "$active" "$sub"
            ;;
        *)
            printf '  %-24s %s %s/%s\n' "$unit" "$load" "$active" "$sub"
            ;;
    esac
}

render_status() {
    host=$(hostname_text)
    ips=$(ipv4_addresses)
    now=$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)

    printf '\n'
    printf '========================================\n'
    printf ' SkiffOS boot status\n'
    printf '========================================\n'
    printf 'Host: %s\n' "$host"
    printf 'Time: %s\n' "$now"
    printf '\n'

    printf 'IPv4 addresses:\n'
    if [ -n "$ips" ]; then
        printf '%s\n' "$ips"
    else
        printf '  no global IPv4 address yet\n'
    fi
    printf '\n'

    printf 'SSH:\n'
    if [ -n "$ips" ]; then
        first_ip=$(printf '%s\n' "$ips" | while read -r _ addr; do printf '%s\n' "$addr"; break; done)
        printf '  ssh root@%s\n' "$first_ip"
    else
        printf '  add a public key under /etc/skiff/authorized_keys, then ssh root@IP_ADDRESS\n'
    fi
    printf '\n'

    printf 'Services:\n'
    service_state skiff-init.service
    service_state NetworkManager.service
    service_state sshd.service
    service_state docker.service
    service_state skiff-core.service
    printf '\n'

    printf 'Setup progress:\n'
    printf '  skiff-core.service manages container setup when skiff/core is enabled.\n'
    printf '  Follow logs with: journalctl -fu skiff-core.service\n'
    printf '\n'
}

wait_for_network
render_status >"$STATUS_OUTPUT" 2>/dev/null || true
