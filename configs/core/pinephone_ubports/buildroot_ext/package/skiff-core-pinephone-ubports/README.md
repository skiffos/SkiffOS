# Skiff Core based on Ubuntu Ports for PinePhone

This is a skiff core setup based on the UBports distro for PinePhone.

https://gitlab.com/ubports/community-ports/pinephone#how-do-i-install-ubuntu-touch-on-my-pinephone

## Building the Base Image

The base image is downloaded automatically from Docker Hub from
`skiffos/ubports-pinephone-base`. To build this base image:

Fetch the latest download: https://ci.ubports.com/job/rootfs/job/rootfs-pinephone-systemimage/lastSuccessfulBuild/artifact/ubuntu-touch-pinephone.img.xz

Then, mount it as a loop-back device, and build the docker image:

```sh
  xz -d ./ubuntu-touch-pinephone.img.xz
  losetup /dev/loop2 ./ubuntu-touch-pinephone.img
  mkdir mtpt
  mount /dev/loop2p9 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/ubports-pinephone-base:latest
  cd ..
  umount mtpt
  losetup -d /dev/loop2
```
