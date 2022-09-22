![](./resources/images/skiff.png)

## Introduction

[![arXiv](https://img.shields.io/badge/arXiv-2104.00048-b31b1b.svg?style=flat-square)](https://arxiv.org/abs/2104.00048)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4629835.svg)](https://doi.org/10.5281/zenodo.4629835)

[SkiffOS] is a lightweight operating system for [any Linux-compatible computer],
ranging from [RPi], [Odroid], [NVIDIA Jetson], to [Desktop PCs], Laptops (i.e.
[Apple MacBook]), [Phones], [Cloud VMs], and even [Web Browsers]. It is:

 - **Familiar**: uses simple Makefile and KConfig language for configuration.
 - **Flexible**: supports any OS distribution inside containers w/ ssh drop-in.
 - **Portable**: replicate the exact same system across any hardware or arch.
 - **Reliable**: read-only minimal in-RAM host system boots reliably every time.
 - **Reproducible**: offline and deterministic builds for reproducible behavior.

SkiffOS adds a configuration package system to the [Buildroot] cross-compiler,
which makes it easy to re-target applications to new hardware. Packages are
merged together as specified in the `SKIFF_CONFIG` comma-separated environment
variable. For example: `SKIFF_CONFIG=pi/4,core/gentoo` will run Gentoo on a
Raspberry Pi 4.

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
[Web Browsers]: https://copy.sh/v86/?profile=copy/skiffos
[SkiffOS]: ./resources/paper.pdf

## Getting started

[![Support Server](https://img.shields.io/discord/803825858599059487.svg?label=Discord&logo=Discord&colorB=7289da&style=for-the-badge)](https://discord.gg/EKVkdVmvwT)

[Buildroot dependencies] must be installed as a prerequisite.

[Buildroot dependencies]: https://buildroot.org/downloads/manual/manual.html#requirement-mandatory

This example uses `pi/4` for the Raspberry Pi 4, see [Supported Systems].

[Supported Systems]: #supported-systems

[Create a SSH key] on your development machine. Add the public key to your build
with `cp ~/.ssh/*.pub ./overrides/root_overlay/etc/skiff/authorized_keys`. This
will be needed to enable SSH access.

[Create a SSH key]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key

```sh
$ make                             # lists all available options
$ export SKIFF_WORKSPACE=default   # optional: supports multiple SKIFF_CONFIG at once
$ export SKIFF_CONFIG=pi/4,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

After you run `make configure` your `SKIFF_CONFIG` selection will be saved. The
build can be interrupted and later resumed with `make compile`.

`SKIFF_WORKSPACE` defaults to `default` and is used to compile multiple
`SKIFF_CONFIG` simultaneously.

There are many other utility commands made available by Buildroot, which can be
listed using `make br/help`, some examples:

```sh
$ make br/menuconfig # explore Buildroot config menu
$ make br/sdk        # build relocatable SDK for target
$ make br/graph-size # graph the target packages sizes
```

There are other [application packages] available i.e. `apps/podman`.

[application packages]: ./configs/apps

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

### Podman

Use the `apps/podman` configuration package to enable Podman support.

## Supported Systems

![CI](https://github.com/skiffos/SkiffOS/workflows/CI/badge.svg?branch=master)

SkiffOS is based on Buildroot, which can compile operating systems for any
Linux-compatible machine.

Here are the boards/systems currently supported:

| **Board**             | **Config Package**    | **Bootloader**   | **Kernel**      | **Notes**        |
|-----------------------|-----------------------|------------------|-----------------|------------------|
| VirtualBox            | [virt/virtualbox]     | N/A              | ✔ 5.19.10       | Run in VM        |
| [Docker Img]          | [virt/docker]         | N/A              | N/A             | Run in Docker    |
| [Qemu]                | [virt/qemu]           | N/A              | ✔ 5.19.10       | Run in QEmu      |
| [V86] on WebAssembly  | [browser/v86]         | [V86]            | ✔ 5.19.10       | [Run in Browser] |
| [WSL] on Windows      | [virt/wsl]            | N/A              | N/A             | Run in WSL2      |
|-----------------------|-----------------------|------------------|-----------------|------------------|
| [Allwinner Nezha]     | [allwinner/nezha]     | ✔ U-boot 2022.04 | ✔ sm-5.18-rc7   | RISC-V D1        |
| [Apple Macbook]       | [apple/macbook]       | ✔ [rEFInd]       | ✔ 5.19.10       | ✔ Tested         |
| [BananaPi M1+/Pro]    | [bananapi/m1plus]     | ✔ U-Boot 2022.04 | ✔ 5.19.10       | ⚠ Obsolete       |
| [BananaPi M1]         | [bananapi/m1]         | ✔ U-Boot 2022.04 | ✔ 5.19.10       | ⚠ Obsolete       |
| [BananaPi M2+]        | [bananapi/m2plus]     | ✔ U-Boot 2022.04 | ✔ 5.19.10       |                  |
| [BananaPi M2]         | [bananapi/m2]         | ✔ U-Boot 2022.04 | ✔ 5.19.10       | ⚠ Obsolete       |
| [BananaPi M3]         | [bananapi/m3]         | ✔ U-Boot 2022.04 | ✔ 5.19.10       | ✔ Tested         |
| [BeagleBoard X15]     | [beaglebone/x15]      | ✔ U-Boot 2022.04 | ✔ 5.10.109-ti   |                  |
| [BeagleBone AI]       | [beaglebone/ai]       | ✔ U-Boot 2022.04 | ✔ 5.10.109-ti   |                  |
| [BeagleBone Black]    | [beaglebone/black]    | ✔ U-Boot 2022.04 | ✔ 5.10.109-ti   |                  |
| [BeagleBoard BeagleV] | [starfive/visionfive] | ✔ U-Boot 2021.04 | ✔ sv-5.19-rc3   | RISC-V           |
| [Intel x86/64]        | [intel/desktop]       | ✔ [rEFInd]       | ✔ 5.19.10       | ✔ Tested         |
| [ModalAI Voxl2]       | [modalai/voxl2]       | N/A              | ✔ msm-4.19.125  |                  |
| [NVIDIA Jetson AGX]   | [jetson/agx]          | ✔ UEFI           | ✔ [nv-5.10.104] | ✔ Tested         |
| [NVIDIA Jetson Nano]  | [jetson/nano]         | ✔ U-Boot         | ✔ [nv-4.9.309]  | ⚠ Obsolete       |
| [NVIDIA Jetson TX2]   | [jetson/tx2]          | ✔ U-Boot         | ✔ [nv-4.9.309]  | ⚠ Obsolete       |
| [Odroid C2]           | [odroid/c2]           | ✔ U-Boot 2022.07 | ✔ tb-5.18.12    | ⚠ Obsolete       |
| [Odroid C4]           | [odroid/c4]           | ✔ U-Boot 2022.07 | ✔ tb-5.18.12    |                  |
| [Odroid HC1]          | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18.12    | ⚠ Obsolete       |
| [Odroid HC2]          | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18.12    | ✔ Tested         |
| [Odroid HC4]          | [odroid/hc4]          | ✔ U-Boot 2022.07 | ✔ tb-5.18.12    |                  |
| [Odroid M1]           | [odroid/m1]           | ✔ U-Boot 2017.09 | ✔ tb-5.18.12    |                  |
| [Odroid N2]+          | [odroid/n2]           | ✔ U-Boot 2022.07 | ✔ tb-5.18.12    | ✔ Tested         |
| [Odroid U]            | [odroid/u]            | ✔ U-Boot 2022.07 | ✔ tb-5.18.12    | ⚠ Obsolete       |
| [Odroid XU3]          | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18.12    | ⚠ Obsolete       |
| [Odroid XU4]          | [odroid/xu]           | ✔ U-Boot 2017.07 | ✔ tb-5.18.12    | ✔ Tested         |
| [OrangePi Lite]       | [orangepi/lite]       | ✔ U-Boot 2018.05 | ✔ 5.19.10       |                  |
| [OrangePi Zero]       | [orangepi/zero]       | ✔ U-Boot 2018.07 | ✔ 5.19.10       |                  |
| [PcDuino 3]           | [pcduino/3]           | ✔ U-Boot 2019.07 | ✔ 5.19.10       |                  |
| [PcEngines APU2]      | [pcengines/apu2]      | ✔ CoreBoot       | ✔ 5.19.10       |                  |
| [Pi 0]                | [pi/0]                | N/A              | ✔ rpi-5.15.61   | ✔ Tested         |
| [Pi 1]                | [pi/1]                | N/A              | ✔ rpi-5.15.61   |                  |
| [Pi 3] + 1, 2         | [pi/3]                | N/A              | ✔ rpi-5.15.61   | ✔ Tested         |
| [Pi 4]                | [pi/4]                | N/A              | ✔ rpi-5.15.61   | ✔ Tested         |
| [Pi 4] (32bit mode)   | [pi/4x32]             | N/A              | ✔ rpi-5.15.61   | ✔ Tested         |
| [Pine64 H64]          | [pine64/h64]          | ✔ U-Boot 2022.04 | ✔ megi-5.19.1   |                  |
| [PineBook A64]        | [pine64/book_a64]     | ✔ U-Boot (bin)   | ✔ megi-5.19.1   | ⚠ Obsolete       |
| [PineBook Pro]        | [pine64/book]         | ✔ U-Boot (bin)   | ✔ megi-5.19.1   | ✔ Tested         |
| [PinePhone]           | [pine64/phone]        | ✔ U-Boot (bin)   | ✔ megi-5.19.1   | ✔ Tested         |
| [Rock64] rk3328       | [pine64/rock64]       | ✔ U-Boot 2022.04 | ✔ megi-5.19.1   | ✔ Tested         |
| [RockPro64]           | [pine64/rockpro64]    | ✔ U-Boot (bin)   | ✔ megi-5.19.1   | ✔ Tested         |
| [Sipeed LicheeRV]     | [allwinner/licheerv]  | ✔ U-Boot 2022.04 | ✔ sm-5.18-rc7   | RISC-V D1        |
| [StarFive VisionFive] | [starfive/visionfive] | ✔ U-Boot 2021.04 | ✔ sv-5.19-rc3   | RISC-V           |
| [USBArmory Mk2]       | [usbarmory/mk2]       | ✔ U-Boot 2020.10 | ✔ 5.19.10       | ✔ Tested         |
| Valve [Steam Deck]    | [valve/deck]          | N/A              | ✔ valve-5.13.0  |                  |
| [Wandboard]           | [freescale/wandboard] | ✔ U-Boot 2022.04 | ✔ 5.19.10       |                  |

[Allwinner Nezha]: https://linux-sunxi.org/Allwinner_Nezha
[Apple Macbook]: https://wiki.gentoo.org/wiki/Apple_Macbook_Pro_Retina_(early_2013)
[BananaPi M1+/Pro]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M1]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2+]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M3]: http://linux-sunxi.org/Banana_Pi_M3
[BeagleBone AI]: http://beagleboard.org/ai
[BeagleBone Black]: http://beagleboard.org/black
[BeagleBoard X15]: http://beagleboard.org/x15
[BeagleBoard BeagleV]: https://beagleboard.org/static/beagleV/beagleV.html
[Docker Img]: ./docker
[Intel x86/64]: ./configs/intel/x64
[ModalAI Voxl2]: https://www.modalai.com/products/voxl-2
[NVIDIA Jetson AGX]: https://developer.nvidia.com/embedded/jetson-agx-xavier-developer-kit
[NVIDIA Jetson Nano]: https://developer.nvidia.com/embedded/jetson-nano-developer-kit
[NVIDIA Jetson TX2]: https://developer.nvidia.com/embedded/jetson-tx2
[Odroid C2]: https://wiki.odroid.com/odroid-c2/odroid-c2
[Odroid C4]: https://wiki.odroid.com/odroid-c4/odroid-c4
[Odroid HC1]: https://www.hardkernel.com/shop/odroid-hc1-home-cloud-one/
[Odroid HC2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[Odroid HC4]: https://www.hardkernel.com/shop/odroid-hc4/
[Odroid M1]: https://wiki.odroid.com/odroid-m1/odroid-m1
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
[PineBook A64]: https://www.pine64.org/pinebook/
[PineBook Pro]: https://www.pine64.org/pinebook-pro/
[PinePhone]: https://www.pine64.org/pinephone/
[Qemu]: ./configs/virt/qemu
[Rock64]: https://www.pine64.org/devices/single-board-computers/rock64/
[RockPro64]: https://www.pine64.org/rockpro64/
[Run in Browser]:  https://copy.sh/v86/?profile=copy/skiffos
[Sipeed LicheeRV]: https://linux-sunxi.org/Sipeed_Lichee_RV
[StarFive VisionFive]: https://ameridroid.com/products/visionfive-starfive
[Steam Deck]: https://store.steampowered.com/steamdeck
[USBArmory Mk2]: https://github.com/f-secure-foundry/usbarmory
[V86]: https://github.com/copy/v86
[Wandboard]: https://elinux.org/Wandboard
[WSL]: https://docs.microsoft.com/en-us/windows/wsl/
[nv-4.9.309]: https://github.com/skiffos/linux/tree/skiff-jetson-4.9.x
[nv-5.10.104]: https://github.com/skiffos/linux/tree/skiff-jetson-5.10.x
[rEFInd]: https://www.rodsbooks.com/refind/

[allwinner/licheerv]: ./configs/allwinner/licheerv
[allwinner/nezha]: ./configs/allwinner/nezha
[apple/macbook]: ./configs/apple/macbook
[bananapi/m1]: ./configs/bananapi/m1
[bananapi/m2]: ./configs/bananapi/m2
[bananapi/m1plus]: ./configs/bananapi/m1plus
[bananapi/m2plus]: ./configs/bananapi/m2plus
[bananapi/m3]: ./configs/bananapi/m3
[beaglebone/ai]: ./configs/beaglebone
[beaglebone/black]: ./configs/beaglebone
[beaglebone/x15]: ./configs/beaglebone
[browser/v86]: ./configs/browser/v86
[freescale/wandboard]: ./configs/freescale/wandboard
[intel/desktop]: ./configs/intel/desktop
[jetson/agx]: ./configs/jetson/agx
[jetson/nano]: ./configs/jetson/nano
[jetson/tx2]: ./configs/jetson/tx2
[modalai/voxl2]: ./configs/modalai/voxl2
[odroid/c2]: ./configs/odroid
[odroid/c4]: ./configs/odroid
[odroid/m1]: ./configs/odroid
[odroid/hc4]: ./configs/odroid
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
[pine64/book_a64]: ./configs/pine64/book_a64
[pine64/book]: ./configs/pine64/book
[pine64/h64]: ./configs/pine64/h64
[pine64/phone]: ./configs/pine64/phone
[pine64/rock64]: ./configs/pine64/rock64
[pine64/rockpro64]: ./configs/pine64/rockpro64
[starfive/visionfive]: ./configs/starfive/visionfive
[usbarmory/mk2]: ./configs/usbarmory
[valve/deck]: ./configs/valve/deck
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

## SkiffOS Core

[![View
Demo](https://asciinema.org/a/KFjeljuEhMBfmm5klUrkmflHe.svg)](https://asciinema.org/a/KFjeljuEhMBfmm5klUrkmflHe)

SkiffOS Core runs Linux distributions in privileged containers:

 - [YAML configuration] for mapping users to containers
 - systemd and/or other init systems operate as PID 1 inside the container
 - container images can be pulled or compiled from scratch

[YAML configuration]: https://github.com/skiffos/skiff-core#configuration

Adding **skiff/core** to `SKIFF_CONFIG` enables Debian Sid with an XFCE desktop.

Other distributions and images supported:

| **Distribution** | **Config Package** | **Notes**              |
|------------------|--------------------|------------------------|
| [Alpine]         | core/alpine        | OpenRC                 |
| [Debian] Sid     | skiff/core         | Default: XFCE desktop  |
| [Fedora]         | core/fedora        | Minimal desktop        |
| [Gentoo]         | core/gentoo        | Based on latest stage3 |
| [Ubuntu]         | core/ubuntu        | Snaps & Ubuntu Desktop |

Other less frequently updated images:

| **Distribution**        | **Config Package** | **Notes**                 |
|-------------------------|--------------------|---------------------------|
| [DietPi]                | [core/dietpi]      | DietPi applications tool  |
| [NASA cFS] Framework    | [core/nasa_cfs]    | Flight software framework |
| [NASA Fprime] Framework | [core/nasa_fprime] | Flight software framework |
| [NixOS]                 | core/nixos         |                           |
| [NixOS] with [XFCE]     | core/nixos_xfce    |                           |

There are also core images specific to [pine64/phone] and [pine64/book] and [jetson/common].

[Debian]: https://debian.org/
[DietPi]: https://github.com/MichaIng/DietPi
[Alpine]: https://www.alpinelinux.org/
[Gentoo]: https://www.gentoo.org/
[Fedora]: https://www.getfedora.org/
[KDE Neon]: https://neon.kde.org/
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
[pine64/book]: ./configs/pine64/book
[pine64/phone]: ./configs/pine64/phone
[jetson/common]: ./configs/jetson/common

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

## Configuration Packages

SkiffOS supports modular configuration packages: kernel & buildroot configs,
root filesystem overlays, patches, hooks, and other resources.

Layers are named as `namespace/name`. For example, a Raspberry Pi 4
configuration would be `pi/4` and Docker is `apps/docker`.

```
├── cflags:         compiler flags in files
├── buildroot:      buildroot configuration fragments
├── buildroot_ext:  buildroot extensions (extra packages)
├── buildroot_patches: extra Buildroot global patches
│   ├── <packagename>: patch files for Buildroot <packagename>
│   └── <packagename>/<version>: patches for package version
├── busybox:        busybox configuration fragments
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
├── uboot_patches: u-boot .patch files
└── users:         additional buildroot user config files
```

All files are optional.

### Custom Users

To add custom users, add files in the "users" dir with the [makeuser syntax].

[makeuser syntax]: https://buildroot.org/downloads/manual/manual.html#makeuser-syntax

### Out-of-tree configuration packages

You can set the following env variables to control this process:

 - `SKIFF_CONFIG_PATH_ODROID_XU`: Set the path for the ODROID_XU config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon `:` separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the SkiffOS system.

### Overrides

It's often useful to be able to adjust the configs during development without
actually creating a new configuration layer. This can be easily done with the
[overrides](./overrides) layer.

The overrides directory is treated as an additional configuration layer. The
layout of the configuration layers is described above. Overrides is ignored by
Git, and serves as a quick and easy way to modify the configuration.

To apply the changes & re-pack the build, run "make configure compile" again.

## Workspaces

Use Workspaces to compile multiple `SKIFF_CONFIG` combinations simultaneously.

The `SKIFF_WORKSPACE` environment variable controls which workspace is selected.

The directory at `workspaces/$SKIFF_WORKSPACE` contains the Buildroot build directory. 

Configuration files in `overrides/workspaces/$SKIFF_WORKSPACE/` will override
settings for that workspace using the configuration package structure.

## Virtualization

The virt/ packages are designed for running Skiff in various virtualized environments.

### Qemu

Here is a minimal working example of running Skiff in Qemu:

```sh
$ SKIFF_CONFIG=virt/qemu make configure compile
$ make cmd/virt/qemu/run
```

### Docker

Here is a minimal working example of running SkiffOS in Docker:

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

You can use `nmcli` on the device to manage `NetworkManager`, and any connection
definitions written by `nmcli device wifi connect` or similar will automatically
be written to the persist partition and persisted to future boots.

To connect to WiFi: `nmcli device wifi connect myssid password mypassword.`

The configuration file format for these connections is [documented
here](http://manpages.ubuntu.com/manpages/wily/man5/nm-settings-keyfile.5.html)
with examples.

Example for a WiFi network called `mywifi` with password `mypassword`:

```
[connection]
id=mywifi
uuid=12f6c21d-f077-4b95-a4cb-bf41555d87a5
type=wifi

[wifi]
mode=infrastructure
ssid=mywifi

[wifi-security]
key-mgmt=wpa-psk
psk=mypassword

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto
```

Network configuration files are plaintext files located at either of:

 - `/etc/NetworkManager/system-connections/` inside the build image
 - `/mnt/persist/skiff/connections/` on the persist partition.

To add the above example to your build:

 - `gedit ./overrides/root_overlay/etc/NetworkManager/system-connections/mywifi`
 - paste the above plaintext & save
 - run "make compile" to update the image with the changes.

### SSH Keys

The system will generate the authorized_keys file for the users on startup.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition
 
Your SSH public key will usually be located at `~/.ssh/id_ed25519.pub`.

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
