# Skiff Core based on LibreELEC

This configuration runs the LibreELEC Generic x86_64 root filesystem as the
Skiff Core container. LibreELEC boots with systemd and keeps its `kodi.target`
default target, so Kodi starts as the primary application inside the core
container.

The default container user is `root`, with shell `/bin/sh`.

https://libreelec.tv

## Using this configuration

This example is for a standard Intel/AMD x86_64 desktop PC, matching the
LibreELEC Generic image.

The `SKIFF_CONFIG` comma-separated environment variable selects which
configuration layers should be merged together to configure the build.

```sh
$ make                                      # lists all available layers
$ export SKIFF_CONFIG=intel/desktop,core/libreelec
$ make configure                            # configure the system
$ make compile                              # build the system
```

After you run `make configure` Skiff will remember what you selected in
`SKIFF_CONFIG`. The compile command instructs Skiff to build the host system.
The LibreELEC core container image is pulled from Quay on first boot.

You can add your SSH public key to the target image by adding it to
`overrides/root_overlay/etc/skiff/authorized_keys/my-key.pub`, or by adding it
to your own custom configuration package.

Once the build is complete, flash the system to the target disk. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash                 # switch to root
$ blkid                     # find the target disk
$ export INTEL_DESKTOP_DISK=/dev/sdz # make sure this is right
$ make cmd/intel/desktop/format      # format the device
$ make cmd/intel/desktop/install     # install SkiffOS
```

The device needs to be formatted only one time. After that, the install command
can update SkiffOS without clearing persistent state. The persist partition is
not touched during install, so saved Kodi data, Docker state, and Skiff Core
configuration remain in place.

## Connecting to the system

If you need to add your SSH key after the system is configured, mount the
persist partition and save your `id_rsa.pub` at `skiff/keys/mykey.pub`.

Connect to the core container as `core`:

```sh
$ ssh core@my-ip-address
```

This configuration maps the `core` login to the LibreELEC container's `root`
user with `/bin/sh`. You can also ssh to `root` to access the SkiffOS host
system.

Edit `/mnt/persist/skiff/core/config.yaml` to change the core image, users,
bind mounts, or container runtime options. LibreELEC persistent state is stored
under `/mnt/persist/skiff/core/repos/libreelec/`.

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
- masks host-visible server daemons: sshd, Samba, and RPCBind;
- leaves Avahi enabled so Kodi can publish AirPlay/RAOP and other mDNS
  services on the host network.

Bluetooth is left enabled because it is a plausible LibreELEC media feature.

## AirPlay discovery

Kodi's AirPlay server listens on the host network when
`services.airplay=true`, but AirPlay clients discover it through mDNS. The
container must run with host networking and `avahi-daemon.service` must not be
masked or disabled.

On a running system, check the container with:

```sh
docker inspect core --format '{{.HostConfig.NetworkMode}}'
docker exec core systemctl --no-pager status avahi-daemon.service
docker exec core avahi-browse -at
```

The expected discovery record for Kodi AirPlay audio is `_raop._tcp`, for
example `Kodi (LibreELEC)`. Kodi may not publish `_airplay._tcp` unless video
AirPlay support is enabled and supported by the Kodi build.

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
