# Skiff Core based on Jellyfin

This configuration runs the official `jellyfin/jellyfin:latest` Docker image as
the Skiff Core container.

The Jellyfin web UI is available on port `8096` of the SkiffOS host. The
container uses host networking so Jellyfin can advertise itself on the LAN and
use DLNA discovery without manual port forwarding.

Jellyfin is a headless media server. It starts the web application, but it does
not draw anything on the attached display. Use a browser or Jellyfin client on
the LAN to complete setup and use the server.

The default SSH login is `core`, mapped to the container's `root` user with
`/usr/bin/bash`. The upstream Jellyfin image runs the Jellyfin process as
`root`, so this configuration does not modify the image or create a separate
application user.

https://jellyfin.org

## Using this configuration

This example is for a standard Intel/AMD x86_64 desktop PC.

The `SKIFF_CONFIG` comma-separated environment variable selects which
configuration layers should be merged together to configure the build.

```sh
$ make                                      # lists all available layers
$ export SKIFF_CONFIG=intel/desktop,core/jellyfin
$ make configure                            # configure the system
$ make compile                              # build the system
```

After you run `make configure` Skiff will remember what you selected in
`SKIFF_CONFIG`. The compile command instructs Skiff to build the host system.
The Jellyfin container image is pulled from Docker Hub on first boot.

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
not touched during install, so saved Jellyfin data and Skiff Core
configuration remain in place.

## Connecting to Jellyfin

Open the Jellyfin web UI from another machine on the LAN:

```text
http://my-ip-address:8096
```

The SkiffOS display will remain on the host console or whatever other UI the
selected board configuration provides. Jellyfin itself is managed through the
web UI.

Connect to the core container shell as `core`:

```sh
$ ssh core@my-ip-address
```

This configuration maps the `core` login to the Jellyfin container's `root`
user with `/usr/bin/bash`. You can also ssh to `root` to access the SkiffOS
host system.

## Storage layout

Edit `/mnt/persist/skiff/core/config.yaml` to change the core image, users,
bind mounts, or container runtime options.

By default, persistent state is stored under:

- `/mnt/persist/skiff/core/repos/jellyfin/config:/config`
- `/mnt/persist/skiff/core/repos/jellyfin/cache:/cache`
- `/mnt/persist/media:/media`

Put media files under `/mnt/persist/media`, or edit the `/media` bind mount in
`config.yaml` to point at your own media library path.

## How it is set up

The SkiffOS config lives in `configs/core/jellyfin` and follows the normal
Skiff Core package shape:

```text
configs/core/jellyfin/
  buildroot/jellyfin
  buildroot_ext/Config.in
  buildroot_ext/external.desc
  buildroot_ext/external.mk
  buildroot_ext/package/skiff-core-jellyfin/
  metadata/dependencies
  metadata/description
```

The Buildroot fragment enables `BR2_PACKAGE_SKIFF_CORE_JELLYFIN`. The package
installs `coreenv-defconfig.yaml` into `/opt/skiff/coreenv` so the Skiff Core
service can pull and run `jellyfin/jellyfin:latest`.

The runtime config uses:

- the upstream image entrypoint, `/jellyfin/jellyfin`;
- persistent `/config` and `/cache`;
- `/mnt/persist/media` mounted at `/media`;
- host networking for port `8096`, DLNA, and LAN discovery;
- the container `root` user for `ssh core@...` shell access.
