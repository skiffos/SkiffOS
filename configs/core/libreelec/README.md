# Skiff Core based on LibreELEC

This configuration runs the LibreELEC Generic x86_64 root filesystem as the
Skiff Core container. LibreELEC boots with systemd and keeps its `kodi.target`
default target, so Kodi starts as the primary application inside the core
container.

The default container user is `root`, with shell `/bin/sh`.

https://libreelec.tv

## How it is set up

The SkiffOS config lives in `configs/core/libreelec` and follows the normal
Skiff Core package shape:

```text
configs/core/libreelec/
  buildroot/libreelec
  buildroot_ext/Config.in
  buildroot_ext/external.desc
  buildroot_ext/external.mk
  buildroot_ext/package/skiff-core-libreelec/
  metadata/dependencies
  metadata/description
```

The Buildroot fragment enables `BR2_PACKAGE_SKIFF_CORE_LIBREELEC`. The package
installs the `coreenv` Dockerfile and `coreenv-defconfig.yaml` into
`/opt/skiff/coreenv` so the Skiff Core service can pull or run
`skiffos/skiff-core-libreelec:latest`.

The runtime config uses:

- `/lib/systemd/systemd` as the entrypoint.
- `container=docker` in the environment.
- privileged host integration with `/dev`, `/lib/modules`, `/run/udev`, `/mnt`,
  host networking, host IPC, and host UTS.
- persistent LibreELEC state at
  `/mnt/persist/skiff/core/repos/libreelec/storage:/storage` and
  `/mnt/persist/skiff/core/repos/libreelec/flash:/flash`.
- persistent logs and temp space at `/mnt/persist/skiff/core/repos/log:/var/log`
  and `/mnt/persist/skiff/core/repos/tmp:/var/tmp`.

## Building the base image

LibreELEC does not publish a Docker base image, so the base image is imported
from the official Generic x86_64 disk image. The `SYSTEM` file in the first
partition is the LibreELEC squashfs root filesystem.

Run this on a SkiffOS host or another Linux machine with Docker, loop-device
support, `partprobe`, and `unsquashfs`:

```sh
cd /mnt/persist
wget https://releases.libreelec.tv/LibreELEC-Generic.x86_64-12.2.1.img.gz
gzip -d LibreELEC-Generic.x86_64-12.2.1.img.gz

mkdir -p mtpt libreelec
losetup /dev/loop2 ./LibreELEC-Generic.x86_64-12.2.1.img
partprobe /dev/loop2
mount /dev/loop2p1 ./mtpt

unsquashfs -d /mnt/persist/libreelec ./mtpt/SYSTEM
cd /mnt/persist/libreelec
tar -c . | docker import - skiffos/skiff-core-libreelec:base

cd /mnt/persist
umount ./mtpt
losetup -d /dev/loop2
rmdir ./mtpt
```

The base image can then be published for reuse:

```sh
docker tag skiffos/skiff-core-libreelec:base \
  quay.io/skiffos/skiff-core-libreelec:base
docker push quay.io/skiffos/skiff-core-libreelec:base
```

## Building the tuned Skiff Core image

The `coreenv/Dockerfile` starts from `skiffos/skiff-core-libreelec:base`, clears
host-owned filesystem state, masks host-owned services, then squashes the result
back to a single image layer.

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

## Image tuning

The first prototype booted after replacing an accidentally copied Manjaro-based
Dockerfile. LibreELEC has BusyBox and systemd, not `pacman`, so distro-specific
package cleanup from another core config should not be reused.

SkiffOS owns the host mounts, kernel state, networking, and persistence. The
LibreELEC Dockerfile therefore:

- empties `/etc/fstab`;
- creates `/flash`, `/storage`, `/run`, `/run/lock`, `/tmp`, and `/var/log`;
- clears stale volatile state under `/run`, `/tmp`, and `/var/cache`;
- keeps LibreELEC's `kodi.target`;
- masks mount, remount, fsck, growfs, swap, sysctl, and udev units;
- masks network/firewall units: ConnMan, ConnMan VPN, iwd, and iptables;
- masks host-visible server daemons: sshd, Samba, Avahi, and RPCBind.

Bluetooth is left enabled because it is a plausible LibreELEC media feature.

## Runtime smoke test

After building the image, run it with the same shape as the Skiff Core
defconfig and inspect systemd:

```sh
docker run --rm -d -t \
  --name skiff-core-libreelec-test \
  --entrypoint /lib/systemd/systemd \
  --env container=docker \
  --stop-signal RTMIN+3 \
  --workdir / \
  --mount type=bind,src=/dev,dst=/dev \
  --mount type=bind,src=/etc/hostname,dst=/etc/hostname,readonly \
  --mount type=bind,src=/lib/modules,dst=/lib/modules,readonly \
  --mount type=bind,src=/mnt,dst=/mnt \
  --mount type=bind,src=/run/udev,dst=/run/udev \
  --mount type=bind,src=/mnt/persist/skiff/core/repos/libreelec/storage,dst=/storage \
  --mount type=bind,src=/mnt/persist/skiff/core/repos/libreelec/flash,dst=/flash \
  --mount type=bind,src=/mnt/persist/skiff/core/repos/log,dst=/var/log \
  --mount type=bind,src=/mnt/persist/skiff/core/repos/tmp,dst=/var/tmp \
  --privileged \
  --cap-add ALL \
  --ipc host \
  --uts host \
  --network host \
  --security-opt seccomp=unconfined \
  --security-opt apparmor=unconfined \
  --tmpfs /run:rw,noexec,nosuid,size=65536k \
  --tmpfs /run/lock:rw,noexec,nosuid,size=65536k \
  skiffos/skiff-core-libreelec:latest

docker logs --tail=220 skiff-core-libreelec-test
docker exec skiff-core-libreelec-test systemctl --no-pager --failed
docker exec skiff-core-libreelec-test systemctl --no-pager status kodi.target
docker stop skiff-core-libreelec-test
```

Expected result:

- `kodi.service` starts.
- `kodi.target` is reached.
- `systemctl --failed` reports zero failed units.
- A second boot with persistent `/storage` has no machine-id warning.
