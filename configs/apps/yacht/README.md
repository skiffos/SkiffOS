# Yacht
 
> Web UI for managing Docker containers.

## Introduction

![DEMO](https://raw.githubusercontent.com/SelfhostedPro/Yacht/master/readme_media/Yacht-Demo.gif "templates")

[Yacht](https://yacht.sh) is a web interface for managing docker containers with
an emphasis on templating to provide one-click deployments.

The default login is **admin@yacht.local**.

## Configuring with the OS Image

To automatically start it on your SkiffOS host, include the `apps/yacht` layer:

```
# For example:
export SKIFF_CONFIG=pi/4,core/gentoo,apps/yacht
export SKIFF_WORKSPACE=pi4
make configure compile
```

The Docker image is multi-architecture and built from the project Dockerfile.

## Running on a Existing System

To run Yacht on an existing SkiffOS system without including it in the OS image
configuration, you can simply ssh to root and run the container:

```sh
$ ssh root@my-skiff-host
$ docker run \
  --name=yacht \
  --restart=always \
  -d -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/persist/yacht-config:/config \
  quay.io/skiffos/selfhostedpro-yacht:latest
```

The container will start on port 8000.
