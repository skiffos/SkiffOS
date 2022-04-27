![](./resources/images/skiff.png)

## Introduction

[![arXiv](https://img.shields.io/badge/arXiv-2104.00048-b31b1b.svg?style=flat-square)](https://arxiv.org/abs/2104.00048)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4629835.svg)](https://doi.org/10.5281/zenodo.4629835)

[SkiffOS] is a lightweight operating system for [any Linux-compatible computer],
ranging from [RPi], [Odroid], [NVIDIA Jetson], to [Desktop PCs], Laptops (i.e.
[Apple MacBook]), [Phones], [Cloud VMs], and more. It is:

 - **Familiar**: uses simple Makefile and KConfig language for configuration.
 - **Flexible**: supports any OS distribution inside containers w/ ssh drop-in.
 - **Portable**: replicate the exact same system across any hardware or arch.
 - **Reliable**: read-only minimal in-RAM host system boots reliably every time.
 - **Reproducible**: offline and deterministic builds for reproducible behavior.

SkiffOS adds a configuration layering system to the [Buildroot] cross-compiler,
which makes it easy to re-target applications to new hardware. Layers are merged
together as specified in the `SKIFF_CONFIG` comma-separated environment
variable. As a basic example: `SKIFF_CONFIG=pi/4,core/gentoo` starts Gentoo on a
Raspberry Pi 4 in a Docker container.

The default configuration produces a minimal (~100Mb) in-RAM host OS with SSH
and network connectivity, and includes a comprehensive set of debug tools. The
host OS can be easily remotely updated with the push_image script, using rsync.

The "skiff/core" layer enables Docker ("apps/docker") and a default environment
based on Ubuntu with a full graphical desktop environment. Others including
"core/gentoo" and "core/dietpi" are available.

Most Linux devices have a unique set of requirements for kernel, firmware, and
hardware support packages. The SkiffOS host OS separates hardware-specific
support from the containerized user environments, simplifying management of
updates across multiple hardware combinations.

[any Linux-compatible computer]: https://linux-hardware.org/index.php?d=SkiffOS
[Apple MacBook]: https://linux-hardware.org/?probe=6dc90bec41
[Buildroot]: https://buildroot.org
[Cloud VMs]: https://imgur.com/a/PXCYnjT
[Desktop PCs]: https://linux-hardware.org/?probe=267ab5de51
[NVIDIA Jetson]: https://linux-hardware.org/?probe=184d1b1c05
[Odroid]: https://linux-hardware.org/?probe=927be03a24
[Phones]: https://linux-hardware.org/?probe=329e6f9308
[RPi]: https://linux-hardware.org/?probe=c3d8362f28
[SkiffOS]: ./resources/paper.pdf

## Getting started

[![Support Server](https://img.shields.io/discord/803825858599059487.svg?label=Discord&logo=Discord&colorB=7289da&style=for-the-badge)](https://discord.gg/EKVkdVmvwT)

[Buildroot dependencies] must be installed as a prerequisite.

[Buildroot dependencies]: https://buildroot.org/downloads/manual/manual.html#requirement-mandatory

This example uses `pi/4`, which can be replaced with any of the hardware support
packages listed in the [Supported Systems](#supported-systems) table.

```sh
$ make                             # lists all available layers
$ export SKIFF_WORKSPACE=default   # optional: supports multiple SKIFF_CONFIG at once
$ export SKIFF_CONFIG=pi/4,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

After you run `make configure` your `SKIFF_CONFIG` selection will be saved and
automatically restored in future sessions. The compile command builds the OS.

The optional `SKIFF_WORKSPACE` variable defaults to `default`, but is useful for
compiling multiple `SKIFF_CONFIG` simultaneously. Each workspace is isolated
from the others and can have a completely different configuration. The build can
be interrupted and resumed with `make compile` as needed.

You will need a SSH public key to access the system. If you don't have one,
[create a SSH key] on your development machine. Add the public key (usually
located at `~/.ssh/id_rsa.pub`) to your build by copying it to
`overrides/root_overlay/etc/skiff/authorized_keys/my-key.pub`. The keys can also
be added to a configuration layer for future use.

[create a SSH key]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key

There are many other utility commands made available by Buildroot, which can be
listed using `make br/help`, some examples:

```sh
$ make br/menuconfig # optionally explore Buildroot config
$ make br/sdk        # build relocatable SDK for target
$ make br/graph-size # graph the target packages sizes
```

You can add `apps/portainer` to `SKIFF_CONFIG` to enable the Portainer UI.

### Flashing the SD Card

Once the build is complete, it's time to flash the system to a SD card. You will
need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export PI_SD=/dev/sdz # make sure this is right!
$ make cmd/pi/common/format  # tell skiff to format the device
$ make cmd/pi/common/install # tell skiff to install the os
```

The device needs to be formatted only one time, after which, the install command
can be used to update the SkiffOS images without clearing the persistent data.
The persist partition is not touched in this step, so anything you save there,
including all Docker containers and system configuration, will not be modified.

### Connecting

Connect using SSH to `root@my-ip-address` to access the SkiffOS system, and
connect to `core@my-ip-address` to access the "Core" system container. See the
section above about SSH public keys if you get a password prompt.

The mapping between users and containers can be edited in the
`/mnt/persist/skiff/core/config.yaml` file.

### OTA Upgrade

The system can then be upgraded over-the-air (OTA) using the rsync script:

```sh
$ ./scripts/push_image.bash root@my-ip-address
```

The SkiffOS upgrade (or downgrade) will take effect on next reboot.

## Supported Systems

![CI](https://github.com/skiffos/SkiffOS/workflows/CI/badge.svg?branch=master)

SkiffOS is based on Buildroot, which can compile operating systems for any
Linux-compatible machine.

Here are the boards/systems currently supported:

| **Board**            | **Config Package**    | **Bootloader**   | **Kernel**     | **Notes**     |
|----------------------|-----------------------|------------------|----------------|---------------|
| [Docker Img]         | [virt/docker]         | N/A              | N/A            | Run in Docker |
| [Qemu]               | [virt/qemu]           | N/A              | ✔ 5.17.4       | Run in QEmu   |
| VirtualBox           | [virt/virtualbox]     | N/A              | ✔ 5.17.4       | Run in VM     |
| [WSL] on Windows     | [virt/wsl]            | N/A              | N/A            | Run in WSL2   |
|----------------------|-----------------------|------------------|----------------|---------------|
| [Allwinner Nezha]    | [allwinner/nezha]     | ✔ U-boot 2022.04 | ✔ sm-5.14-rc4  | RISC-V D1     |
| [Apple Macbook]      | [apple/macbook]       | ✔ [rEFInd]       | ✔ 5.17.4       | ✔ Tested      |
| [BananaPi M1+/Pro]   | [bananapi/m1plus]     | ✔ U-Boot 2022.04 | ✔ 5.17.4       | ⚠ Obsolete    |
| [BananaPi M1]        | [bananapi/m1]         | ✔ U-Boot 2022.04 | ✔ 5.17.4       | ⚠ Obsolete    |
| [BananaPi M2]        | [bananapi/m2]         | ✔ U-Boot 2022.04 | ✔ 5.17.4       | ⚠ Obsolete    |
| [BananaPi M2+]       | [bananapi/m2plus]     | ✔ U-Boot 2022.04 | ✔ 5.17.4       |               |
| [BananaPi M3]        | [bananapi/m3]         | ✔ U-Boot 2022.04 | ✔ 5.17.4       | ✔ Tested      |
| [Wandboard]          | [freescale/wandboard] | ✔ U-Boot 2022.04 | ✔ 5.17.4       |               |
| [Intel x86/64]       | [intel/x64]           | ✔ Grub           | ✔ 5.17.4       | ✔ Tested      |
| [NVIDIA Jetson Nano] | [jetson/nano]         | ✔ U-Boot         | ✔ [nv-4.9.309] | ✔ Tested      |
| [NVIDIA Jetson TX2]  | [jetson/tx2]          | ✔ U-Boot         | ✔ [nv-4.9.309] | ✔ Tested      |
| [Odroid C2]          | [odroid/c2]           | ✔ U-Boot 2022.04 | ✔ tb-5.18-rc4  | ⚠ Obsolete    |
| [Odroid C4]          | [odroid/c4]           | ✔ U-Boot 2022.04 | ✔ tb-5.18-rc4  |               |
| [Odroid HC1]         | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18-rc4  | ⚠ Obsolete    |
| [Odroid HC2]         | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18-rc4  | ✔ Tested      |
| [Odroid N2]+         | [odroid/n2]           | ✔ U-Boot 2022.04 | ✔ tb-5.18-rc4  | ✔ Tested      |
| [Odroid U]           | [odroid/u]            | ✔ U-Boot 2022.04 | ✔ tb-5.18-rc4  | ⚠ Obsolete    |
| [Odroid XU3]         | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18-rc4  | ⚠ Obsolete    |
| [Odroid XU4]         | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18-rc4  | ✔ Tested      |
| [OrangePi Lite]      | [orangepi/lite]       | ✔ U-Boot 2018.05 | ✔ 5.17.4       |               |
| [OrangePi Zero]      | [orangepi/zero]       | ✔ U-Boot 2018.07 | ✔ 5.17.4       |               |
| [PcDuino 3]          | [pcduino/3]           | ✔ U-Boot 2019.07 | ✔ 5.17.4       |               |
| [PcEngines APU2]     | [pcengines/apu2]      | ✔ CoreBoot       | ✔ 5.17.4       |               |
| [Pi 0]               | [pi/0]                | N/A              | ✔ rpi-5.15.33  | ✔ Tested      |
| [Pi 1]               | [pi/1]                | N/A              | ✔ rpi-5.15.33  |               |
| [Pi 3] + 1, 2        | [pi/3]                | N/A              | ✔ rpi-5.15.33  | ✔ Tested      |
| [Pi 4]               | [pi/4]                | N/A              | ✔ rpi-5.15.33  | ✔ Tested      |
| [Pi 4] (32bit mode)  | [pi/4x32]             | N/A              | ✔ rpi-5.15.33  | ✔ Tested      |
| [Pine64 H64]         | [pine64/h64]          | ✔ U-Boot         | ✔ 5.17.4       |               |
| [PineBook Pro]       | [pine64/book]         | ✔ U-Boot (bin)   | ✔ megi-5.17.4  |               |
| [PinePhone]          | [pine64/phone]        | ✔ U-Boot (bin)   | ✔ megi-5.17.4  | ✔ Tested      |
| [Rock64] rk3328      | [pine64/rock64]       | ✔ U-Boot         | ✔ 5.17.4       | ✔ Tested      |
| [RockPro64]          | [pine64/rockpro64]    | ✔ U-Boot (bin)   | ✔ 5.17.4       | ✔ Tested      |
| [USBArmory Mk2]      | [usbarmory/mk2]       | ✔ U-Boot 2020.10 | ✔ 5.17.4       | ✔ Tested      |

[Allwinner Nezha]: https://linux-sunxi.org/Allwinner_Nezha
[Apple Macbook]: https://wiki.gentoo.org/wiki/Apple_Macbook_Pro_Retina_(early_2013)
[BananaPi M1+/Pro]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M1]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2+]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M3]: http://linux-sunxi.org/Banana_Pi_M3
[Docker Img]: ./docker 
[Intel x86/64]: ./configs/intel/x64
[NVIDIA Jetson Nano]: ./configs/jetson
[NVIDIA Jetson TX2]: ./configs/jetson
[Odroid C2]: https://wiki.odroid.com/odroid-c2/odroid-c2
[Odroid C4]: https://wiki.odroid.com/odroid-c4/odroid-c4
[Odroid HC1]: https://www.hardkernel.com/shop/odroid-hc1-home-cloud-one/
[Odroid HC2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[Odroid N2]: https://wiki.odroid.com/odroid-n2/odroid-n2
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
[Pine64 H64]: https://www.pine64.org/pine-h64-ver-b/
[PineBook Pro]: https://www.pine64.org/pinebook-pro/
[PinePhone]: https://www.pine64.org/pinephone/
[Qemu]: ./configs/virt/qemu
[Rock64]: https://www.pine64.org/devices/single-board-computers/rock64/
[RockPro64]: https://www.pine64.org/rockpro64/
[USBArmory Mk2]: https://github.com/f-secure-foundry/usbarmory
[Wandboard]: https://elinux.org/Wandboard
[WSL]: https://docs.microsoft.com/en-us/windows/wsl/
[nv-4.9.309]: https://github.com/skiffos/linux/tree/skiff-jetson-4.9.x
[rEFInd]: https://www.rodsbooks.com/refind/

[allwinner/nezha]: ./configs/allwinner/nezha
[apple/macbook]: ./configs/apple/macbook
[bananapi/m1]: ./configs/bananapi/m1
[bananapi/m2]: ./configs/bananapi/m2
[bananapi/m1plus]: ./configs/bananapi/m1plus
[bananapi/m2plus]: ./configs/bananapi/m2plus
[bananapi/m3]: ./configs/bananapi/m3
[freescale/wandboard]: ./configs/freescale/wandboard
[intel/x64]: ./configs/intel/x64
[jetson/nano]: ./configs/jetson/nano
[jetson/tx2]: ./configs/jetson/tx2
[odroid/c2]: ./configs/odroid
[odroid/c4]: ./configs/odroid
[odroid/n2]: ./configs/odroid
[odroid/u]: ./configs/odroid
[odroid/xu]: ./configs/odroid
[orangepi/lite]: ./configs/orangepi/lite
[orangepi/zero]: ./configs/orangepi/zero
[pcduino/3]: ./configs/pcduino/3
[pcengines/apu2]: ./configs/pcengines/apu2
[pi/0]: ./configs/pi
[pi/1]: ./configs/pi
[pi/3]: ./configs/pi
[pi/4]: ./configs/pi
[pi/4x32]: ./configs/pi
[pine64/book]: ./configs/pine64/book
[pine64/h64]: ./configs/pine64/h64
[pine64/phone]: ./configs/pine64/phone
[pine64/rock64]: ./configs/pine64/rock64
[pine64/rockpro64]: ./configs/pine64/rockpro64
[usbarmory/mk2]: ./configs/usbarmory
[virt/docker]: ./configs/virt/docker
[virt/qemu]: ./configs/virt/qemu
[virt/virtualbox]: ./configs/virt/virtualbox
[virt/wsl]: ./configs/virt/wsl

All targets marked "tested" use automated end-to-end testing on real hardware.
Targets marked "Obsolete" are discontinued by their manufacturer but still have
a corresponding SkiffOS configuration and should still work.

Adding support for a board involves creating a Skiff configuration package for
the board, as described above. If you have a device that is not yet supported by
SkiffOS, please **[open an issue].**

[open an issue]: https://github.com/skiffos/SkiffOS/issues/new

## Skiff Core

[![View Demo](https://asciinema.org/a/KFjeljuEhMBfmm5klUrkmflHe.svg)](https://asciinema.org/a/KFjeljuEhMBfmm5klUrkmflHe)

The Skiff Core subsystem, enabled with the `skiff/core` layer or by selecting
any of the core environment packages, automatically configures mappings between
users and containerized environments. It maps incoming SSH sessions accordingly:

 - Configured using a YAML configuration file `skiff-core.yaml**.
 - The container image is either pulled or built from scratch.
 - systemd and/or other init systems operate as PID 1 inside the container.

This allows any distribution to be run as a containerized guest with Skiff. The
config file structure is flexible, and allows for any number of containers,
users, and images to be defined and built. Desktop environments work as expected.

### Environment Presets

**skiff/core** comes with Debian Sid with a XFCE desktop on default.

Any existing GNU/Linux system with compatibility with the running kernel version
can be loaded as a Docker image with the `docker import` command.

All core configurations work with all target platforms.

The primary distributions and images supported are:

| **Distribution**  | **Config Package** | **Notes**              |
|-------------------|--------------------|------------------------|
| [Alpine] Linux    | core/alpine        | OpenRC                 |
| [Debian] Bullseye | [core/debian]      | XFCE desktop           |
| [Gentoo]          | core/gentoo        | Based on latest stage3 |
| Ubuntu            | skiff/core         | Ubuntu Jammy desktop   |

Other less frequently updated images:

| **Distribution**           | **Config Package**            | **Notes**                 |
|----------------------------|-------------------------------|---------------------------|
| [DietPi]                   | [core/dietpi]                 | DietPi applications tool  |
| [NASA cFS] Framework       | [core/nasa_cfs]               | Flight software framework |
| [NASA Fprime] Framework    | [core/nasa_fprime]            | Flight software framework |
| [NixOS]                    | core/nixos                    |                           |
| [NixOS] for PinePhone      | core/pinephone_nixos          |                           |
| [NixOS] with [XFCE]        | core/nixos_xfce               |                           |
| PineBook [Manjaro] KDE     | core/pinebook_manjaro_kde     | KDE Variant               |
| PinePhone [KDE Neon]       | core/pinephone_neon           | Ubuntu-based KDE Neon     |
| PinePhone [Manjaro] KDE    | core/pinephone_manjaro_kde    | KDE Variant               |
| PinePhone [Manjaro] Lomiri | core/pinephone_manjaro_lomiri | Lomiri variant            |
| PinePhone [Manjaro] Phosh  | core/pinephone_manjaro_phosh  | Phosh variant             |
| PinePhone [UBTouch]        | core/pinephone_ubtouch        | Ubuntu touch              |

[Debian]: https://debian.org/
[DietPi]: https://github.com/MichaIng/DietPi
[Alpine]: https://www.alpinelinux.org/
[Gentoo]: https://www.gentoo.org/
[KDE Neon]: https://neon.kde.org/
[Manjaro]: https://manjaro.org/
[NASA cFS]: https://github.com/nasa/cFS
[NASA Fprime]: https://github.com/nasa/fprime
[NixOS]: https://nixos.org
[UBTouch]: https://ubuntu-touch.io
[Ubuntu]: https://ubuntu.com/
[XFCE]: https://www.xfce.org/

[core/debian]: ./configs/core/debian
[core/dietpi]: ./configs/core/dietpi
[core/nasa_cfs]: ./configs/core/nasa_cfs
[core/nasa_fprime]: ./configs/core/nasa_fprime

### Customize Config

The default configuration creates a user named "core" mapped into a container,
but this can be adjusted with the `skiff-core.yaml` configuration file:

```yaml
containers:
  core:
    image: skiffos/skiff-core-gentoo:latest
    [...]
users:
  core:
    container: core
    containerUser: core
    [...]
```

The [full example config] is in the skiff/core package.

To customize a running system, edit `/mnt/persist/skiff/core/config.yaml` and
run `systemctl restart skiff-core` to apply. You may need to delete existing
containers and restart skiff-core to re-create them after changing their config.

The config format is defined in [the skiff-core repo].

[the skiff-core repo]: https://github.com/skiffos/skiff-core/blob/master/config/core_config.go
[full example config]: ./configs/skiff/core/buildroot_ext/package/skiff-core-defconfig/coreenv-defconfig.yaml

## Release Channels

There are three release channels: **next**, **master**, and **stable**.

Skiff can be upgraded or downgraded (rolled back) independently from the
persistent storage partition. This allows for easy OTA, and significant
improvements in confidence when upgrading system components.

## Configuration Layers

Skiff supports modular configuration layers. A configuration directory contains
kernel configs, buildroot configs, system overlays, and misc. files.

Layers are named as `namespace/name`. For example, a Raspberry Pi 4
configuration would be `pi/4` and Docker is `apps/docker`.

```
├── cflags:         compiler flags in files
├── buildroot:      buildroot configuration fragments
├── buildroot_ext:  buildroot extensions (extra packages)
├── buildroot_patches: extra Buildroot global patches
│   ├── <packagename>: patch files for Buildroot <packagename>
│   └── <packagename>/<version>: patches for package version
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

 - `SKIFF_CONFIG_PATH_ODROID_XU`: Set the path for the ODROID_XU config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon `:` separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the Skiff system.

### Local Overrides

It's often useful to be able to adjust the configs locally during development
without actually creating a new configuration layer. This can be easily done
with the [overrides](./overrides) layer.

The overrides directory is treated as an additional configuration layer. The
layout of the configuration layers is described above. Overrides is ignored by
Git, and serves as a quick and easy way to modify the configuration.

To apply the changes & re-pack the build, run "make configure compile" again.

## Workspaces

Workspaces allow you to configure and compile multiple systems at a time.

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
$ SKIFF_CONFIG=virt/docker,skiff/core make configure compile
$ make cmd/virt/docker/buildimage
$ make cmd/virt/docker/run

# inside container
$ su - core
```

The build command compiles the image, and run executes it.

You can execute a shell inside the container with:

```sh
$ make cmd/virt/docker/exec
# alternatively
$ docker exec -it skiff sh
```

Alternatively, run the latest demo release on Docker Hub:

```
docker run -t -d --name=skiff \
  --privileged \
  --cap-add=NET_ADMIN \
  --security-opt seccomp=unconfined \
  --stop-signal=SIGRTMIN+3 \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $(pwd)/skiff-persist:/mnt/persist \
  skiffos/skiffos:latest
```

## Configuration

SkiffOS can be configured dynamically with files in the "persist" partition.

### Hostname

Set the hostname by placing the desired hostname in the `skiff/hostname` file on
the persist partition. You could also set this in one of your config packages by
writing the desired hostname to `/etc/hostname`.

### NetworkManager

Network configurations are loaded from `/etc/NetworkManager/system-connections`
or from the persist partition at `skiff/connections`.

You can use `nmcli` on the device to manage `NetworkManager`, and any connection
definitions written by `nmcli device wifi connect` or similar will automatically
be written to the persist partition and persisted to future boots.

To connect to WiFi: `nmcli device wifi connect myssid password mypassword.`

The configuration file format for these connections is [documented
here](http://manpages.ubuntu.com/manpages/wily/man5/nm-settings-keyfile.5.html)
with examples.

### SSH Keys

The system will generate the authorized_keys file for the users on startup.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition
 
Your SSH public key will usually be located at `~/.ssh/id_rsa.pub`.

### Mount a Disk to a Container

To mount a Linux disk, for example an `ext4` partition, to a path inside a
Docker container, you can use the Docker Volumes feature:

```sh
# create a volume for the storage drive
docker volume create --driver=local --opt device=/dev/disk/by-label/storage storage

# run a temporary container to view the contents
docker run --rm -it -v storage:/storage --workdir /storage alpine:edge sh
```

The volume can be mounted into a Skiff Core container by adding to the mounts
list in `/mnt/persist/skiff/core/config.yaml`:

```yaml
containers:
  core:
    image: skiffos/skiff-core-gentoo:latest
    mounts:
      - storage:/mnt/storage
```

After adding the mount, delete and re-create the container:

```sh
docker rm -f core
systemctl restart skiff-core
```

## Support

SkiffOS is built & supported by [Aperture Robotics], LLC.

[Aperture Robotics]: https://github.com/aperturerobotics

Community contributions and discussion are welcomed!

Please file a [GitHub issue] and/or [Join Discord] with any questions.

[GitHub issue]: https://github.com/skiffos/skiffos/issues/new
[Join Discord]: https://discord.gg/EKVkdVmvwT

... or feel free to reach out on [Matrix Chat]!

[Matrix Chat]: https://matrix.to/#/#aperturerobotics:matrix.org
