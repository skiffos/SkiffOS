# SkiffOS

![](./resources/images/skiff.png)

## Introduction

Skiff is a lightweight cross-compiled Linux OS focusing on creating a consistent
and reproducible environment across any compute architecture.

Skiff loads a small ~30MB image containing the kernel and core system into RAM
at boot-time. This ensures that the system will always boot up into a consistent
state, ideal for embedded and mission-critical environments. Sudden failure of
the storage drive does not break the system, as the core OS runs from memory.

As a modular configuration package manager for the industry-standard
[Buildroot](http://buildroot.org) embedded Linux tool, Skiff allows for a
consistent developer experience and application execution environment across any
compute platform. The compact nature of the system creates a minimal attack
surface for security.

The "skiff/core" layer brings in the Docker container system, and introduces a
user which is backed by a container. When logging into this user, the session is
executed inside a container with a familiar operating system, such as Ubuntu.
This decouples the core OS (kernel, init manager, container manager) from the
userspace, allowing the userspace container to become portable between machines.

This repository includes configurations supporting a variety of embedded
platforms, including Raspberry Pi and ODROID boards. Skiff can also run inside a
Docker container, a qemu VM, as a typical x86_64 system, or a cloud VM. It's
easy to add support for new boards and architectures, and the OS can be fully
customized with Skiff's configuration package system.

## Demo: Run in Docker

You can now demo Skiff with a single command!

```sh
# Execute the latest Skiff release with Docker.
docker run -d --name=skiff \
  --privileged \
  --cap-add=NET_ADMIN \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  --tmpfs /run \
  --tmpfs /run/lock \
  -t \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $(pwd)/skiff-persist:/mnt/persist \
  paralin/skiffos:latest
# Run a shell in the container.
docker exec -it skiff sh
# Inside the container, switch to "Skiff core"
su - core
```

This will download and execute Skiff in a container.

## Getting started

Building a system with Skiff is easy! This example will build a OS for a Pi 3.

You can type `make` at any time to see a status and help printout. Do this now,
and look at the list of configuration packages. Select which ones you want, and
set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ make                             # observe status output
$ export SKIFF_CONFIG=skiff/systemd,pi/3
$ make configure                   # configure the system
$ make compile                     # build the system
```

After you run `make configure` Skiff will remember what you selected in
`SKIFF_CONFIG`. The compile command instructs Skiff to build the system.

```sh
$ make br/menuconfig               # optionally explore config
$ make br/linux-menuconfig         # optionally explore Linux config
```

You can also enable Docker or other packages in the target:

```sh
SKIFF_CONFIG=skiff/systemd,pi/3,apps/docker
```

Once the build is complete, it's time to flash the system to a SD card. You will
need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export PI_SD=/dev/sda # make sure this is right!
$ make cmd/pi/3/format  # tell skiff to format the device
$ make cmd/pi/3/install # tell skiff to install the os
```

After you format a card, you do not need to do so again. You can call the
install command as many times as you want to update the system. The persist
partition is not touched in this step, so anything you save there, including
Docker state and system configuration, will not be touched in the upgrade.

Skiff configurations are evaluated in the order they are specified. An example
configuration might look like:

```sh
SKIFF_CONFIG=pi/3,apps/kodi make configure compile
```

Some operating systems are not compatible with the Skiff build system, due to
the host not using glibc, or using some outdated or otherwise incompatible
libraries for the fairly recent Skiff distribution.

If you encounter any errors related to host-* packages, you can try [building
Skiff inside Docker](./docker-build).

## Workspaces

Workspaces allow you to configure and compile multiple systems in tandem.

Set `SKIFF_WORKSPACE` to the name of the workspace you want to use. The
Buildroot setup will be constructed in `workspaces/$SKIFF_WORKSPACE`. You can
also place configuration files in `overrides/workspaces/$SKIFF_WORKSPACE/` to
override settings for that particular workspace locally.

## Virtualization

The virt/ packages are designed for running Skiff in various virtualized environments.

### Qemu

Here is a minimal working example of running Skiff in Qemu:

```sh
$ SKIFF_CONFIG=virt/qemu make configure compile
$ make cmd/virt/qemu/run
```

### Docker

Here is a minimal working example of running Skiff in Docker:

```sh
$ SKIFF_CONFIG=virt/docker make configure compile
$ make cmd/virt/docker/buildimage
$ make cmd/virt/docker/run
```

The build command compiles the image, and run executes it.

You can execute a shell inside the container with:

```sh
$ make cmd/virt/docker/exec
# alternatively
$ docker exec -it skiff sh
```

## Configuration Packages

Skiff supports modular configuration packages. A configuration directory
contains kernel configs, buildroot configs, system overlays, etc.

These packages are denoted as `namespace/name`. For example, an ODROID XU4
configuration would be `odroid/xu4`.

Configuration package directories should have a depth of 2, where the first
directory is the category name and the second is the package name.

### Package Layout

A configuration package is laid out into the following directories:

```
├── buildroot:      buildroot configuration fragments
├── buildroot_ext:  buildroot extensions (extra packages)
├── extensions:     extra commands to add to the build system
│   └── Makefile
├── hooks:          scripts hooking pre/post build steps
│   ├── post.sh
│   └── pre.sh
├── kernel:         kernel configuration fragments
├── kernel_patches: kernel .patch files
├── root_overlay:   root overlay files
├── metadata:       metadata files
│   ├── commands
│   ├── dependencies
│   ├── description
│   └── unlisted
├── resources:     files used by the configuration package
├── scripts:       any scripts used by the extensions
├── uboot:         u-boot configuration fragments
└── uboot_patches: u-boot .patch files
```

All files are optional.

### Out-of-tree configuration packages

You can set the following env variables to control this process:

 - `SKIFF_CONFIG_PATH_ODROID_XU4`: Set the path for the ODROID_XU4 config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the Skiff system.

### Local Overrides

It's often useful to be able to adjust the buildroot, kernel, or other
configurations locally during development without actually creating a new
configuration layer. This can be easily done with the overrides system.

The `overrides` directory, as well as the
`overrides/workspaces/$SKIFF_WORKSPACE` directory, are automatically used as
additional Skiff configuration packages. You can follow the Skiff configuration
package format as defined below to override any of the settings in Buildroot or
the Linux kernel, add extra Buildroot packages, add build hooks, etc.

## Supported Systems

SkiffOS is based on Buildroot, which can compile operating systems for virtually
any machine. Therefore, SkiffOS also works on nearly any architecture or board.

Here are the boards/systems currently supported by Skiff:

| **Board**          | **Config Package** | **Bootloader**       | **Kernel**      | **Notes**              |
| ---------------    | -----------------  | -------------------- | --------------- | ---------------------- |
| [Docker Img]       | virt/docker        | N/A                  | N/A             | Run SkiffOS in Docker  |
| [Qemu]             | virt/qemu          | N/A                  | ✔ 5.6.19        | Run SkiffOS in QEmu    |
| [Apple Macbook]    | apple/macbook      | [rEFInd]             | ✔ 5.6.19        |                        |
| [BananaPi M1]      | bananapi/m1        | ✔ U-Boot 2019.01 Src | ✔ 5.6.19        |                        |
| [BananaPi M1+/Pro] | bananapi/m1plus    | ✔ U-Boot 2019.01 Src | ✔ 5.6.19        |                        |
| [BananaPi M2+]     | bananapi/m2plus    | ✔ U-Boot 2019.01 Src | ✔ 5.6.19        | ⚠ Untested             |
| [BananaPi M3]      | bananapi/m3        | ✔ U-Boot 2019.01 Src | ✔ 5.6.19        |                        |
| [Intel x86/64]     | intel/x64          | Grub                 | ✔ 5.6.19        |                        |
| [Odroid HC1]       | odroid/xu4         | ✔ U-Boot 2019.04 Src | ✔ 4.14.176      |                        |
| [Odroid HC2]       | odroid/xu4         | ✔ U-Boot 2019.04 Src | ✔ 4.14.176      |                        |
| [Odroid U]         | odroid/u           | ✔ U-Boot 2016.03 Src | ✔ Linux CIP     | ⚠ Discontinued         |
| [Odroid XU3]       | odroid/xu4         | ✔ U-Boot 2019.04 Src | ✔ 4.14.176      | ⚠ Discontinued         |
| [Odroid XU4]       | odroid/xu4         | ✔ U-Boot 2019.04 Src | ✔ 4.14.176      |                        |
| [OrangePi Lite]    | orangepi/lite      | ✔ U-Boot 2018.05 Src | ✔ 4.17.15       | ⚠ Untested             |
| [OrangePi Zero]    | orangepi/zero      | ✔ U-Boot 2018.07 Src | ✔ 4.17.15       | ⚠ Untested             |
| [PcDuino 3]        | pcduino/3          | ✔ U-Boot 2019.07 Src | ✔ 5.6.19        |                        |
| [PcEngines APU2]   | pcengines/apu2     | ✔ CoreBoot           | ✔ 5.6.19        |                        |
| [Pi 0]             | pi/0               | N/A                  | ✔ 4.19.127      |                        |
| [Pi 1]             | pi/1               | N/A                  | ✔ 4.19.127      |                        |
| [Pi 3] (and 1/2)   | pi/3               | N/A                  | ✔ 4.19.127      |                        |
| [Pi 4]             | pi/4               | N/A                  | ✔ 4.19.127      |                        |

[Apple Macbook]: https://wiki.gentoo.org/wiki/Apple_Macbook_Pro_Retina_(early_2013)
[BananaPi M1+/Pro]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M1]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2+]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M3]: http://linux-sunxi.org/Banana_Pi_M3
[Docker Img]: ./docker 
[Intel x86/64]: ./configs/intel/x64
[Odroid C2]: https://wiki.odroid.com/odroid-c2/odroid-c2
[Odroid HC1]: https://www.hardkernel.com/shop/odroid-hc1-home-cloud-one/
[Odroid HC2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[Odroid U]: https://wiki.odroid.com/old_product/odroid-x_u_q/odroid_u3/odroid-u3
[Odroid XU3]: https://wiki.odroid.com/old_product/odroid-xu3/odroid-xu3
[Odroid XU4]: https://wiki.odroid.com/odroid-xu4/odroid-xu4
[OrangePi Lite]: http://linux-sunxi.org/Xunlong_Orange_Pi_One_%26_Lite
[OrangePi Zero]: http://linux-sunxi.org/Xunlong_Orange_Pi_Zero
[PcDuino 3]: https://linux-sunxi.org/LinkSprite_pcDuino3
[PcEngines APU2]: https://www.pcengines.ch/apu2.htm
[Pi 0]: https://www.raspberrypi.org/products/raspberry-pi-zero/
[Pi 1]: https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/
[Pi 3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[Pi 4]: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/
[rEFInd]: https://www.rodsbooks.com/refind/
[Qemu]: ./configs/virt/qemu

Adding support for a board involves creating a Skiff configuration package for
the board, as described above.

If you have a board that is not yet supported by SkiffOS, please **open an
issue,** and we will work with you to integrate and test the new platform.

## Systemd

If the **skiff/systemd** package is included, the Skiff initialization scripts
are included and the system can be configured as described below.

### NetworkManager

Skiff can use NetworkManager to manage network connections.

Network configurations are loaded from `/etc/NetworkManager/system-connections`
and from `skiff/connections` on the persist partition.

The configuration file format for these connections is [documented
here](http://manpages.ubuntu.com/manpages/wily/man5/nm-settings-keyfile.5.html)
with examples.

You can use `nmcli` on the device to manage `NetworkManager`, and any connection
definitions written by `nmcli device wifi connect` or similar will automatically
be written to the persist partition and persisted to future boots.

### Hostname

You can set the hostname by placing the desired hostname in the `skiff/hostname`
file on the persist partition. You could also set this in one of your config
packages by writing the desired hostname to `/etc/hostname`.

### SSH Keys

The system on boot will generate the authorized_keys file for root.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition

## Skiff Core

[View Demo!](https://asciinema.org/a/RiWjwpTXMmK7d45TXjl0I20r9)

Users can work within a familiar, traditional, persistent OS environment if
desired. This is called the "core" user within Skiff. If this feature is
enabled:

 - On first boot, the system will build the **core** container image.
 - The correct base image for the architecture is selected.
 - The default image contains Ubuntu and systemd.
 - SSH connections to the **core** user are dropped into the Docker container

This allows virtually any workflow to be migrated to Skiff. The config file
structure is flexible, and allows for any number of containers, users, and
images to be defined and built.

To enable, add the `skiff/core` package to your `SKIFF_CONFIG` comma-separated
list.

To customize the core environment, edit the file at `skiff/core/config.yaml` on
the persist partition. The default config will be placed there on first boot.

The default config can be overridden with a file at
`/opt/skiff/coreenv/defconfig.yaml`.

### Install Docker

You can install Docker inside the core environment, and systemd is running, so
you can enable it to correctly auto-start when you first connect.

```bash
ssh core@my-skiff-host
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo docker ps
```

This is "docker inside docker!"

## Example Workloads

This section contains some example workloads you can use to get started. These
examples are Docker based. 

### System Tools with Alpine

Alpine provides a lightweight environment with a package manager (apk) to
install developer tools on-demand. This command will execute a persistent
container named "work" which you can execute a shell inside to interact with.
This workflow is similar to how Skiff Core drops SSH sessions into Docker
containers as an optional feature.

```bash
# Replace arm32v6/alpine with alpine if on x86 or amd64 systems
docker run \
	--name=work -d \
    --pid=host --uts=host --net=host \
    --privileged \
    -v /:/root-fs -v /dev:/dev \
    --privileged \
    arm32v6/alpine:edge \
    bin/sleep 99999
    
# Execute a shell in the container.
docker exec -it work sh

# Update the packages.
apk upgrade --update

# Add a package.
apk add vim
apk add alpine-sdk # adds compilers
```

Some useful tools to try:

 - htop: interactive process manager similar to top
 - atop: shows CPU statistics and process information as well as summaries of
   network interface load.
 - bwm-ng: simple lightweight UI to show rx/tx and total bandwidth of all interfaces.
 - bmon: detailed UI, shows all details of any network errors experienced and
   current bandwidth on all interfaces.
 - nload: shows incoming and outgoing network load.
 - nethogs: shows what processes are using network traffic.

### System Performance Monitoring with Glances

System performance monitoring and benchmarking is easy with the glances tool.

The below command can be executed after sshing to the "root" user to start the
performance monitoring UI on port 61208 on the device (for the ARM
architecture):

```bash
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --pid=host --net=host \
  --restart=always \
  --name=glances \
  --detach=true \
  --privileged \
  paralin/glances-arm:latest glances -w
```

### Container Performance Monitoring with Cadvisor

System and container performance monitoring and benchmarking is easy with the cadvisor tool.

The below command can be executed after sshing to the "root" user to start the performance monitoring UI on port 8080 on the device:

```bash
docker run \
 --volume=/var/run:/var/run:rw \
 --volume=/sys:/sys:ro \
 --volume=/var/lib/docker/:/var/lib/docker:ro \
 --publish=8080:8080 \
 --detach=true \
 --name=cadvisor \
 braingamer/cadvisor-arm:latest
```

## Support

If you encounter issues or questions at any point when using Skiff, please file
a [GitHub issue](https://github.com/paralin/SkiffOS/issues/new).
