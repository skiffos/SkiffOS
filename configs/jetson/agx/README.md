# NVIDIA Jetson AGX

This package targets the NVIDIA Jetson AGX Orin and Xavier series of boards.

Reference:

 - https://nv-tegra.nvidia.com/r/gitweb?p=linux-5.10.git;a=summary
 - https://nv-tegra.nvidia.com/r/linux-5.10.git
 - https://nv-tegra.nvidia.com/r/linux-nvidia.git
 - https://nv-tegra.nvidia.com/r/gitweb?p=linux-nvidia.git

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=jetson/agx
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system via USB. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
# follow the "Flashing" process described below.
```

Note: the "flashusb" recovery mode flashing approach will overwrite the
"persist" data as well. This is a limitation of the flashing process and
partition layout on the internal emmc.

## Flashing via USB

Flashing to the internal eMMC is done by booting to the official recovery mode,
and flashing the system from there.

The recovery mode of the Jetson AGX is used to flash SkiffOS. Entering recovery:

 - Start with the machine powered off + fully unplugged.
 - Connect a micro-USB cable from the host PC to the target board.
 - Connect the board to power.
 - Hold down the Force Recovery button.
 - Hold down the Power button.
 - Release the Power button.
 - Wait a moment.
 - Release the Force Recovery button.

SkiffOS uses Linux4Tegra `flash.sh` to flash via USB.

Select your board and set it to `SKIFF_NVIDIA_BOARD` below:

- `jetson-orin-nano-devkit`: Jetson Orin Nano Devkit
- `jetson-agx-orin-devkit`: Jetson AGX Orin Devkit

To flash via USB:

```
export SKIFF_NVIDIA_USB_FLASH=confirm
export SKIFF_NVIDIA_BOARD=jetson-agx-orin-devkit
make cmd/jetson/agx/flashusb
```

This will run the `flash.sh` script from L4T, and will setup the kernel, u-boot,
persist + boot-up partition mmcblk0p1.

The flash script will overwrite the entire persist partition. This is due to a
limitation in the flashing process: the jetson internal EMMC partition layout
has a single "app" partition. The recovery mode is used to flash a ext4 image to
that partition containing the system files. Partial flashing would need separate
partitions to work correctly. Please use the `push_image.sh` script to update
after the initial install, see OTA Updates below.

## OTA Updates

After SkiffOS is installed and booted, the system can be over-the-air updated by
using the `scripts/push_image.sh` script:

```
./scripts/push_image.sh root@myjetsonagx
```

## Available Boards

The following configurations are available in Linux4Tegra:

```
igx-orin-devkit
jetson-agx-orin-devkit-as-jao-32gb
jetson-agx-orin-devkit-as-nano4gb
jetson-agx-orin-devkit-as-nano8gb
jetson-agx-orin-devkit-as-nx-16gb
jetson-agx-orin-devkit-as-nx-8gb
jetson-agx-orin-devkit-industrial-maxn
jetson-agx-orin-devkit-industrial-qspi
jetson-agx-orin-devkit-industrial
jetson-agx-orin-devkit-maxn
jetson-agx-orin-devkit
jetson-orin-nano-devkit-nvme
jetson-orin-nano-devkit
```

These can be passed with `SKIFF_NVIDIA_BOARD` when flashing.

```
export SKIFF_NVIDIA_BOARD=jetson-agx-orin-devkit-industrial
```

The default is `jetson-agx-orin-devkit`.

`maxn` mode refers to the maximum power mode for NVIDIA's Jetson AGX Orin
modules. It allows the module to operate at its highest power and performance
levels. For example, in the case of the 32GB Orin module, the MAXN mode
corresponds to the 40W power mode. When the module is set to MAXN mode, it
operates at its maximum performance capabilities. This mode is typically set
using commands such as sudo /usr/sbin/nvpmodel -m 01 but can be set in the board
configuration environment variable as well by using:

```
export SKIFF_NVIDIA_BOARD=jetson-agx-orin-devkit-maxn
```
