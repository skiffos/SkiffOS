# Skiff Core based on Manjaro KDE for PineBook

This is a skiff core setup based on the [Manjaro KDE for PineBook] distribution.

[Manjaro KDE for PineBook]: https://manjaro.org/downloads/arm/pinebook-pro/arm8-pinebook-pro-kde-plasma/

https://manjaro.org

## Building the Base Image

The base image is `skiffos/skiff-core-pinebook-manjaro-kde:latest`. To build
this image:

Fetch the latest download to manjaro.img.

Then, mount it as a loop-back device, and build the docker image:

```sh
  xz -d ./manjaro.img.xz
  losetup /dev/loop2 ./manjaro.img
  mkdir mtpt
  partprobe /dev/loop2
  mount /dev/loop2p2 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/skiff-core-pinebook-manjaro-kde:base
  cd ..
  umount mtpt
  losetup -d /dev/loop2
  cd /opt/skiff/coreenv/skiff-core-pinebook-manjaro-kde/
  docker build -t skiffos/skiff-core-pinebook-manjaro-kde:latest .
```
