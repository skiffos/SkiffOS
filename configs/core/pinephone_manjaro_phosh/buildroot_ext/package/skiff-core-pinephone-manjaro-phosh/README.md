# Skiff Core based on Manjaro Phosh for Pinephone

This is a skiff core setup based on the Manjaro Phosh for PinePhone build.

## Building the Base Image

The base image is downloaded automatically from Docker Hub from
`skiffos/skiff-core-pinephone-manjaro-phosh:latest`. To build this image:

Fetch the latest download: https://osdn.net/projects/manjaro-arm/storage/pinephone/phosh/dev/

Then, mount it as a loop-back device, and build the docker image:

```sh
  gzip -d ./pinephone-manjaro.img.gz
  losetup /dev/loop2 ./pinephone-manjaro.img
  mkdir mtpt
  mount /dev/loop2p2 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/skiff-core-pinephone-manjaro-phosh:base
  cd ..
  umount mtpt
  losetup -d /dev/loop2
  cd /opt/skiff/coreenv/skiff-core-pinephone-manjaro-phosh/
  docker build -t skiffos/skiff-core-pinephone-manjaro-phosh:latest .
```

