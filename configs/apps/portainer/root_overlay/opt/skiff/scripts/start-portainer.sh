#!/bin/bash
set -eo pipefail

echo "Checking for portainer data volume..."
if ! docker volume inspect portainer_data > /dev/null; then
    echo "Creating portainer data volume..."
    docker volume create portainer_data
fi

echo "Checking for portainer server container..."
if ! docker inspect portainer > /dev/null; then
    echo "Creating portainer server container..."
    docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
           --restart=always \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v portainer_data:/data \
           cr.portainer.io/portainer/portainer-ce:2.11.0
else
    echo "Portainer server already running."
    docker start portainer || true
fi

echo "Checking for portainer agent container..."
if ! docker inspect portainer_agent > /dev/null; then
    echo "Creating portainer agent container..."
    docker run -d --restart=always \
           -p 9001:9001 \
           --name portainer_agent \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v /var/lib/docker/volumes:/var/lib/docker/volumes \
           cr.portainer.io/portainer/agent:2.11.0
else
    echo "Portainer agent already running."
    docker start portainer_agent || true
fi
