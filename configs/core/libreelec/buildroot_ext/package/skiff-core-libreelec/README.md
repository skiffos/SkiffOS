# Skiff Core based on LibreELEC

This configuration runs the LibreELEC Generic x86_64 root filesystem as the
Skiff Core container. The image keeps LibreELEC's `kodi.target` default target
and masks services SkiffOS already owns on the host, such as mount setup, udev,
network management, firewall setup, SSH, Samba, and Avahi.

The default container user is `root`, with shell `/bin/sh`.

https://libreelec.tv

## Building the Base Image

The `latest` image is built from a Docker base image imported from the
LibreELEC Generic disk image. The base image build is manual because LibreELEC
does not publish a Docker base image.

On a SkiffOS host:

```sh
cd /mnt/persist
wget https://releases.libreelec.tv/LibreELEC-Generic.x86_64-12.2.1.img.gz
gzip -d LibreELEC-Generic.x86_64-12.2.1.img.gz

mkdir -p mtpt libreelec
losetup /dev/loop2 ./LibreELEC-Generic.x86_64-12.2.1.img
partprobe /dev/loop2
mount /dev/loop2p1 ./mtpt

# The SYSTEM file in the first partition is the LibreELEC squashfs root.
unsquashfs -d /mnt/persist/libreelec ./mtpt/SYSTEM
cd /mnt/persist/libreelec
tar -c . | docker import - skiffos/skiff-core-libreelec:base

cd /mnt/persist
umount ./mtpt
losetup -d /dev/loop2
rmdir ./mtpt
```

The base image may then be published for reuse:

```sh
docker tag skiffos/skiff-core-libreelec:base \
  quay.io/skiffos/skiff-core-libreelec:base
docker push quay.io/skiffos/skiff-core-libreelec:base
```

Build and publish the Skiff Core image from this package's `coreenv`
Dockerfile:

```sh
cd /opt/skiff/coreenv/skiff-core-libreelec
docker pull quay.io/skiffos/skiff-core-libreelec:base
docker tag quay.io/skiffos/skiff-core-libreelec:base \
  skiffos/skiff-core-libreelec:base
docker build -t skiffos/skiff-core-libreelec:latest .
docker tag skiffos/skiff-core-libreelec:latest \
  quay.io/skiffos/skiff-core-libreelec:latest
docker push quay.io/skiffos/skiff-core-libreelec:latest
```

For local prototyping, edit `/mnt/persist/skiff/core/config.yaml` to use
`skiffos/skiff-core-libreelec:latest`, remove the old core container, and run
`systemctl restart skiff-core`.
