# BeagleBone

This set of configuration layers configures Buildroot to produce a BSP image for
the [BeagleBone] series of boards (and similar) by BeagleBoard.

Note: BB Black: see the Booting from SD card section below.

References:

 - https://elinux.org/Beagleboard:BeagleBoneBlack_Rebuilding_Software_Image
 - https://github.com/beagleboard/meta-beagleboard
 - https://github.com/RobertCNelson/omap-image-builder

[BeagleBone]: https://beagleboard.org

## Board Compatibility

There are specific layers tuned to each model.

| **Board** | **Config Layer**      |
|-----------|-----------------------|
| [AI]      | beaglebone/ai         |
| [Black]   | beaglebone/black      |
| [X15]     | beaglebone/x15        |
| [beaglev] | [starfive/visionfive] |

Most boards similar to the BeagleBone Black including PocketBeagle are also
supported by the `beaglebone/black` configuration.

[AI]: http://beagleboard.org/ai
[Black]: http://beagleboard.org/black
[X15]: https://beagleboard.org/x15
[beaglev]: ../starfive
[starfive/visionfive]: ../starfive/visionfive

## Compiling SkiffOS

The OS must be compiled before building an image or flashing an SD card.

[Buildroot dependencies] must be installed as a prerequisite.

[Buildroot dependencies]: https://buildroot.org/downloads/manual/manual.html#requirement-mandatory

This example uses `beaglebone/ai`, which can be replaced with any of the
hardware support packages listed in the table above.

```sh
$ make                             # lists all available layers
$ export SKIFF_WORKSPACE=default   # optional: supports multiple SKIFF_CONFIG at once
$ export SKIFF_CONFIG=beaglebone/ai,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

See the SkiffOS readme for more information.

## Flashing the SD Card

Once the build is complete, it's time to flash the system to a SD card. You will
need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export BEAGLEBONE_SD=/dev/sdz # make sure this is right!
$ make cmd/beaglebone/common/format  # tell skiff to format the device
$ make cmd/beaglebone/common/install # tell skiff to install the os
```

The device needs to be formatted only one time, after which, the install command
can be used to update the SkiffOS images without clearing the persistent data.
The persist partition is not touched in this step, so anything you save there,
including all Docker containers and system configuration, will not be modified.

## Booting from SD Card

**beaglebone/black**: to boot from the MicroSD card instead of the EMMC, you
will need to hold the "boot" button down while powering on the board. However,
the button is "latching" so future re-boots will go to the MicroSD card.

## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=default
# set the output path
export BEAGLEBONE_IMAGE=./beagle-image.img
# make the image
make cmd/beaglebone/common/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=beagle-image.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.

## Serial Debug Console

The serial debug console is enabled on the debug uart.

The Beaglebone AI has a JST ZH3 connector, you can connect to it with the
following cables available from Digikey:

 - [BBCAI-ND]: Beaglebone AI JST to FTDI adapter
 - [768-1015-ND]: FTDI to USB adapter
 
Connect the two cables together & then to the Beaglebone AI.

Access the serial debug with, for example, screen:

```sh
# access ttyUSB0 at 115200 baudrate
$ screen /dev/ttyUSB0 115200
```

The kernel debug logs should be printed on this serial line on default.
 
[BBCAI-ND]: https://www.digikey.com/en/products/detail/digi-key-electronics/BBCAI/10187731
[768-1015-ND]: https://www.digikey.com/en/products/detail/ftdi-future-technology-devices-international-ltd/TTL-232R-3V3/1836393
