# Yacht
 
> Web UI for managing Docker containers.

## Introduction

![DEMO](https://raw.githubusercontent.com/SelfhostedPro/Yacht/master/readme_media/Yacht-Demo.gif "templates")

[Yacht](https://yacht.sh) is a web interface for managing docker containers with
an emphasis on templating to provide one-click deployments.

## Configuring with the OS Image

To automatically start it on your SkiffOS host, include the `apps/yacht` layer:

```
# For example:
export SKIFF_CONFIG=pi/4,core/gentoo,apps/yacht
export SKIFF_WORKSPACE=pi4
make configure compile
```

The image used is the original `selfhostedpro/yacht` image mirrored to `quay.io`.

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
  -v /mnt/persist/yaght-config:/config \
  selfhostedpro/yacht
```

The container will start on port 8000.
