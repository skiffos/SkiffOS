# Pine64 PinePhone

This configuration package `pine64/phone` compiles a Skiff base operating system
for the Pine64 PinePhone.

References: 

 - https://linux-sunxi.org/PinePhone
 - https://wiki.pine64.org/index.php?title=PinePhone 
 - https://www.ironrobin.net/pureos/git/clover/pinephone
 - https://gitlab.com/groups/postmarketOS/-/milestones/1
 - https://gitlab.com/postmarketOS/pmaports/-/tree/master/device/community/device-pine64-pinephone

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/phone,core/pinephone_neon
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../

## KDE Neon

The `core/pinephone_neon` portion of SKIFF_CONFIG enables "Skiff Core" with
Mobile KDE Neon - a version of KDE optimized for mobile.

This image was built by importing the pinephone KDE Neon image to Docker with
some tweaks. An ~2Gb file will be downloaded at first boot from Docker Hub with
the pinephone KDE Neon base image.

## Upgrading Modem Firmware

The phone comes with a older version of the firmware pre-flashed to the modem.
To upgrade the modem firmware, follow the instructions on the [PinePhone
Firmware Wiki] page.

Reference:

 - [PinePhone Firmware Wiki]
 - https://github.com/Biktorgj/quectel_eg25_recovery
 - https://github.com/Biktorgj/qfirehose
 - https://git.sr.ht/~martijnbraam/pinephone-modemfw/

[PinePhone Firmware Wiki]: https://wiki.pine64.org/wiki/PineModems#Firmware_Recovery
