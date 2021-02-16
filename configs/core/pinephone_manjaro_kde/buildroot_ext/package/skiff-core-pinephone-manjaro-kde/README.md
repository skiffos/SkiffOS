# Skiff Core based on KDE Neon for PinePhone

This is a skiff core setup based on the KDE Neon for PinePhone build.

## Building the Base Image

The base image is downloaded automatically from Docker Hub from
`skiffos/neon-pinephone-base`. To build this base image:

Fetch the latest download: https://images.plasma-mobile.org/pinephone/

Then, mount it as a loop-back device, and build the docker image:

```sh
  gzip -d ./pinephone-manjaro.img.gz
  losetup /dev/loop2 ./pinephone-manjaro.img
  mkdir mtpt
  mount /dev/loop2p2 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/skiff-core-pinephone-manjaro-kde:base
  cd ..
  umount mtpt
  losetup -d /dev/loop2
  cd /opt/skiff/coreenv/skiff-core-pinephone-manjaro-kde/
  docker build -t skiffos/skiff-core-pinephone-manjaro-kde:latest .
```

