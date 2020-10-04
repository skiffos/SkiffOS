# Skiff Core based on KDE Neon for PinePhone

This is a skiff core setup based on the KDE Neon for PinePhone build.

## Building the Base Image

The base image is downloaded automatically from Docker Hub from
`skiffos/neon-pinephone-base`. To build this base image:

Fetch the latest download: https://images.plasma-mobile.org/pinephone/

Then, mount it as a loop-back device, and build the docker image:

```sh
  gzip -d ./plasma-mobile-neon-20201004-132523.img.gz
  losetup /dev/loop2 ./plasma-mobile-neon-20201004-132523.img
  mkdir mtpt
  mount /dev/loop2p1 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/neon-pinephone-base:latest
  cd ..
  umount mtpt
  losetup -d /dev/loop2
```
