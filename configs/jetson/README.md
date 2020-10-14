# NVIDIA Linux for Tegra (L4T)

This configuration package configures Buildroot to produce a BSP image for the
Jetson TX1, TX2, AGX Xavier, or Nano boards.

There are specific configurations for each board, see "Board Compatibility."

References:

 - https://elinux.org/Jetson
 - https://github.com/madisongh/meta-tegra
 - https://developer.nvidia.com/embedded/linux-tegra
 - https://developer.nvidia.com/embedded/faq#jetson-part-numbers
 
Currently tested on the TX2 and Nano. Issue reports welcome.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=jetson/tx2
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system via USB. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
# follow the "Flashing" process described below.
```

The board will boot up into Skiff.

Note: the "flashusb" recovery mode flashing approach will overwrite the
"persist" data as well. This is a limitation of the flashing process and
partition layout on the internal emmc. Read "flashing" below for info. The best
approach for OTA update is to replace the "image" and "rootfs.cpio.gz" and
"modules.squashfs" (if skiff/moduleimg is used) files on the running system.

Note: the Jetson Nano uses a custom u-boot script, similar to other Skiff
boards, and has a separate "format" and "install" script. This allows users to
update Skiff independently of the bootloader and partition layout and other
persistent data. The "install" step will not overwrite any persistent data in
the "persist" partition.

## Board Compatibility

There are specific packages tuned to each model.

| **Board**       | **Config Package** |
| --------------- | -----------------  |
| [Jetson Nano]   | jetson/nano        |
| [Jetson TX2]    | jetson/tx2         |

[Jetson Nano]: https://developer.nvidia.com/embedded/jetson-nano-developer-kit
[Jetson TX2]: https://elinux.org/Jetson_TX2

## TX2: Flashing via USB

Note: this section applies to the Jetson TX2 only.

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

Skiff uses the Tegra for Linux package to flash over USB (flash.sh). The L4T
packages are licensed under the NVIDIA Customer Software License. Skiff will
download the linux4tegra package to your build workspace, and exposes the
contained scripts as Makefile targets.

To flash over USB:

```
export SKIFF_WORKSPACE=myworkspace
export SKIFF_NVIDIA_USB_FLASH="true"
make cmd/jetson/tx2/flashusb
```

This will run the `flash.sh` script from L4T, and will setup the kernel, u-boot,
persist + boot-up partition mmcblk0p1. This may overwrite your existing work so
use it for initial setup only.

After Skiff is installed, the system can be OTA updated by replacing the "Image"
and "initrd" files. The flash script will overwrite the entire persist
partition. This is due to a limitation in the flashing process: the jetson
internal EMMC partition layout has a single "app" partition. The recovery mode
is used to flash a ext4 image to that partition containing the system files.
Partial flashing would need separate partitions to work correctly.

It's possible to flash only u-boot by modifying the flash.sh script, and a
target for this will be added to Skiff later on.

## Nano: Flashing SD Card

Note: this section applies to the Jetson Nano only.

The Jetson Nano boots to a SD card:

```
sudo bash
export SKIFF_WORKSPACE=myworkspace
# Set to the sd card - i.e. /dev/sdb
export NVIDIA_SD=/dev/sdX
# Format the SD card with partition layout + u-boot
make cmd/jetson/nano/format
# Install the latest Skiff release files to the card
make cmd/jetson/nano/install
```

The flashing process should look similar to [this
output](https://asciinema.org/a/V9wuudXPxC0nnImCjkFfmRWy4).

Note: updating Skiff requires running the "install" command (not the "format").
This will not overwrite any persistent data stored on the "persist" partition,
and will only replace files in the /boot directory. The "format" command creates
the initial system partition layout and installs u-boot and other firmware.

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
There are scripts included designed to "upgrade" a factory-flashed TX2 Ubuntu
system to use Skiff, by overwriting the contents of the rootfs partition.

Cboot could be compiled from source, and the source is available from the
official sources, however, Skiff does not (yet) compile cboot.

## Core Image

The nvidia boards come with a Skiff Core configuration which installs the
JetPack debs inside the container. This brings in support for the NVIDIA JetPack
features, even inside the Core docker container, automatically.

## Partition Layout

The required partition layout is somewhat complex and does not provide an
opportunity for separate "persist" and "boot" partitions as typically used by
other Skiff boards:

 - **APP**: at mmcblk0p1: contains the main system read-write filesystem.
 - **TBC**: TegraBoot CPU-side binary.
 - **RP1**: Bootloader DTB binary.
 - **EBT**: CBoot, the final boot stage CPU bootloader binary.
 - **WB0**: Warm boot binary.
 - **BPF**: SC7 entry firmware.
 - **BPF-DTB**: Reserved for future use by BPMP DTB binary; can't remove.
 - **FX**: Reserved for fuse bypass; removeable.
 - **TOS**: Required. Contains TOS binary.
 - **DTB**: Contains kernel DTB binary.
 - **LNX**: Contains U-Boot, which loads and launches the kernel.
 - **EKS**: Contains "the encrypted keys".
 - **BMP**: Contains BMP images for splash screen display during boot.
 - **RP4**: Contains XUSB module’s firmware file, making XUSB a true USB 3.0 host.
 - **GPT**: Contains secondary GPT of the sdcard device.

Unfortunately, the complex parti

# License Acknowledgment

The NVIDIA Linux4Tegra packages are licensed under the NVIDIA Customer Software
License. Skiff does not directly redistribute any parts of the toolkit, but will
download it as a Buildroot package from the NVIDIA servers as part of the build
process. The appropriate licenses can be viewed by triggering the Buildroot
"legal" build step. It is the responsibility of the end user / developer to be
aware of these terms and follow them accordingly.

