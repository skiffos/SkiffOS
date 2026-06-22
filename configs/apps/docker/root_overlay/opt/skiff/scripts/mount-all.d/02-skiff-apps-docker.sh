#!/bin/bash

DOCKER_SERVICE=${DOCKER_SERVICE:=/usr/lib/systemd/system/docker.service}
DOCKER_CONFD=${DOCKER_CONFD:=/etc/systemd/system/docker.service.d}
DOCKER_DAEMON_JSON=${DOCKER_DAEMON_JSON:=/etc/docker/daemon.json}

# Use environment-set DOCKER_PERSIST if available, otherwise use default path.
DOCKER_PERSIST_DEFAULT=$(realpath ${SKIFF_PERSIST}/docker)
DOCKER_PERSIST=${DOCKER_PERSIST:=${DOCKER_PERSIST_DEFAULT}}

docker_legacy_images_exist() {
    local image_dir="${DOCKER_PERSIST}/image"

    if ! [ -d "${image_dir}" ]; then
        return 1
    fi

    if find "${image_dir}" -path "*/imagedb/content/sha256/*" -type f | read -r _; then
        return 0
    fi
    if find "${image_dir}" -path "*/layerdb/sha256/*" -type f | read -r _; then
        return 0
    fi

    local repo_json
    for repo_json in "${image_dir}"/*/repositories.json; do
        if ! [ -f "${repo_json}" ]; then
            continue
        fi
        if jq -e 'type == "object" and length > 0' "${repo_json}" >/dev/null 2>&1; then
            return 0
        fi
    done

    return 1
}

configure_containerd_snapshotter() {
    mkdir -p "$(dirname "${DOCKER_DAEMON_JSON}")"

    if docker_legacy_images_exist; then
        echo "Skipping Docker containerd snapshotter: legacy Docker image metadata exists in ${DOCKER_PERSIST}"
        return 0
    fi

    if ! [ -f "${DOCKER_DAEMON_JSON}" ]; then
        printf "{}\n" > "${DOCKER_DAEMON_JSON}"
    fi

    if ! jq empty "${DOCKER_DAEMON_JSON}" >/dev/null 2>&1; then
        echo "Skipping Docker containerd snapshotter: ${DOCKER_DAEMON_JSON} is not valid JSON"
        return 0
    fi

    if jq -e 'has("containerd-snapshotter") or has("snapshotter") or ((.features // {}) | type == "object" and (has("containerd-snapshotter") or has("snapshotter")))' "${DOCKER_DAEMON_JSON}" >/dev/null; then
        echo "Preserving existing Docker snapshotter setting in ${DOCKER_DAEMON_JSON}"
        return 0
    fi

    if ! jq -e '(.features | type) == "null" or (.features | type) == "object"' "${DOCKER_DAEMON_JSON}" >/dev/null; then
        echo "Skipping Docker containerd snapshotter: ${DOCKER_DAEMON_JSON} has a non-object features value"
        return 0
    fi

    local tmp
    tmp=$(mktemp "${DOCKER_DAEMON_JSON}.tmp.XXXXXX") || return 1
    if jq '.features = ((.features // {}) + {"containerd-snapshotter": true})' "${DOCKER_DAEMON_JSON}" > "${tmp}"; then
        mv "${tmp}" "${DOCKER_DAEMON_JSON}"
        echo "Enabled Docker containerd snapshotter in ${DOCKER_DAEMON_JSON}"
    else
        rm -f "${tmp}"
        return 1
    fi
}

mkdir -p "${DOCKER_CONFD}" "${DOCKER_PERSIST}"
configure_containerd_snapshotter

if [ -f "${DOCKER_SERVICE}" ]; then
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_EXECSTART=$(grep '^ExecStart=.*$' "${DOCKER_SERVICE}" | sed -e "s/ExecStart=//")
    DOCKER_EXECSTART+=" --data-root=\"$DOCKER_PERSIST\""

    echo "Configuring Docker to use systemd-journald"
    DOCKER_EXECSTART+=" --log-driver=journald"

    echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
    printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART\n" > "${DOCKER_CONFD}/execstart.conf"
fi
