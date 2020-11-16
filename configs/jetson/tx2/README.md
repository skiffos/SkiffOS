# NVIDIA Jetson TX2

This configuration package configures Buildroot to produce a BSP image for the
Jetson TX1, TX2, AGX Xavier boards.

There are specific configurations for each board, see [readme](../).

References:

 - https://elinux.org/Jetson
 - https://github.com/madisongh/meta-tegra
 - https://developer.nvidia.com/embedded/linux-tegra
 - https://developer.nvidia.com/embedded/faq#jetson-part-numbers

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

## Remaining Work

The Jetson TX2 currently does not make use of the deferred modules loading via
skiff/moduleimg package. This is because the "rootfs" portion is not included in
the target for the Tx2, and the Jetson TX2 does not yet make use of a
initramfs-based system (it uses a standard ext4 rootfs). This also makes it
difficult to OTA the TX2.

