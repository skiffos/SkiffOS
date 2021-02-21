#!/bin/bash
set -eo pipefail

if docker inspect yacht > /dev/null ; then
    exit 0
fi

IMAGE=quay.io/skiffos/selfhostedpro-yacht:latest
if ! docker inspect ${IMAGE}; then
    if [ -f /mnt/rootfs/resources/images/${IMAGE}.tar.gz ]; then
        echo "Loading image from resources..."
        cat /mnt/rootfs/resources/images/${IMAGE}.tar.gz |\
            gzip -d |\
            docker load
    else
        echo "Image ${IMAGE} does not exist in resources, pulling..."
        docker pull ${IMAGE}
    fi
fi

if ! docker inspect yacht > /dev/null ; then
    echo "Creating container..."
    docker run -d \
	         --name=yacht \
           --restart=always \
           -d -p 8000:8000 \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v /mnt/persist/yaght-config:/config \
           ${IMAGE}
fi
