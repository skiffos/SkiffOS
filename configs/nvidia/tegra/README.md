# NVIDIA Linux for Tegra (L4T)

This configuration package `nvidia/jetson` configures Buildroot to produce a BSP
image for the Jetson TX1, TX2, AGX Xavier, or Nano boards.

References:

 - https://elinux.org/Jetson
 - https://github.com/madisongh/meta-tegra
 - https://developer.nvidia.com/embedded/linux-tegra
 
Currently only tested on the TX2. Issue reports welcome.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=nvidia/jetsontx2
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system via USB. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
# follow the "Flashing" process described below.
$ SKIFF_NVIDIA_USB_FLASH=confirm make cmd/nvidia/tegra/flashusb
```

The board will boot up into Skiff.

## Board Compatibility

There are specific packages tuned to each model.

| **Board**       | **Config Package** |
| --------------- | -----------------  |
| [Jetson TX2]    | nvidia/jetsontx2   |

[Jetson TX2]: https://elinux.org/Jetson_TX2

## Bootup Process

The TX2 and recent boards boot from the internal eMMC, at mmcblk0p1. The Jetson
Nano can boot to a SD card.

A "secure boot" process is used, with multiple bootloaders:

 - BootROM -> MB1 (TrustZone)
 - MB2/BPMP -> (Non-Trustzone)
 - Cboot (uses Little Kernel)
 - Uboot
 - Kernel
 
Uboot is flashed to the mmcblk0p1 emmc partition. Skiff compiles u-boot properly
for the boards, however it's not necessary to flash u-boot to begin using it.
There are scripts included designed to "upgrade** a factory-flashed TX2 Ubuntu
system to use Skiff, by overwriting the contents of the rootfs partition.

A script is included to flash u-boot if desired.

Cboot could be compiled from source, and the source is available from the
official sources, however, Skiff does not (yet) compile cboot.

## Flashing

Flashing to the internal eMMC is done by booting to the official recovery mode,
and flashing the system from there. The default factory-flashed TX2 is suitable.

There are a lot of cases where the TX2 will not boot properly unless all of the
peripherals are fully disconnected, power is disconnected, everything fully
resets, and then the power is introduced back again.

The recovery mode of the Jetson is used to flash Skiff. Entering recovery:

 - Start with the machine powered off + fully unplugged.
 - Plug in the device to power, and connect a HDMI display.
 - Connect a micro-USB cable from the host PC to the target board.
 - Power on the device by holding the start button until the red light is lit.
 - Hold down the RST button and REC button simultaneously.
 - Release the RST button while holding down the REC button.
 - Wait a few seconds, then release the REC button.

You may also be able to enter recovery by SSHing to the default system (username
nvidia password nvidia) and entering `sudo reboot --force forced-recovery`.

Skiff uses the Tegra for Linux package to flash over USB (flash.sh). The T4L
packages are licensed under the NVIDIA Customer Software License. Skiff will
download the linux4tegra package to your build workspace, and exposes the
contained scripts as Makefile targets.

To flash over USB:

```
export SKIFF_WORKSPACE=myworkspace
export SKIFF_NVIDIA_USB_FLASH="true"
make cmd/nvidia/tegratx2/usbflash
```

This will run the `flash.sh` script from L4T, and will setup the kernel, u-boot,
persist + boot-up partition mmcblk0p1. This may overwrite your existing work so
use it for initial setup only.

After Skiff is installed, the system can be OTA updated by replacing the "Image"
and "initrd" files.

It's possible to flash only u-boot by modifying the flash.sh script, and a
target for this will be added to Skiff later on.

## Known Issues

There are the following known issues:

 - Skiff tegra4linux core image has the following issues:
   - kde is black-screen after sign in
   - lxde works fine
   - chromium-browser works, has acceleration, but YouTube won't play
   - vlc segfaults
   - mplayer works but is laggy
   - gstreamer works (and is accelerated)

The full desktop experience is not quite possible with the l4t based container,
but we are getting there.
