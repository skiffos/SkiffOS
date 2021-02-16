# Pine64 PinePhone

This configuration package `pine64/phone` compiles a Skiff base operating system
for the Pine64 PinePhone. Most of the other distributions are available as core
configurations.

References: 

 - https://linux-sunxi.org/PinePhone
 - https://wiki.pine64.org/index.php?title=PinePhone 
 - https://www.ironrobin.net/pureos/git/clover/pinephone
 - https://gitlab.com/groups/postmarketOS/-/milestones/1
 - https://gitlab.com/postmarketOS/pmaports/-/tree/master/device/community/device-pine64-pinephone
 - https://xnux.eu/devices/pine64-pinephone.html

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/phone,core/pinephone_manjaro_kde
$ make configure                   # configure the system
$ make compile                     # build the system
```

The `core/pinephone_manjaro_kde` portion of SKIFF_CONFIG enables "Skiff Core"
with Manjaro KDE for PinePhone. See http://manjaro.org for more information.

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../

## Skiff Core: Available Variants


| **Distribution**           | **Config Package**            | **Notes**              |
| ---------------            | -----------------             | ---------------------- |
| PinePhone [KDE Neon]       | core/pinephone_neon           | Ubuntu-based KDE Neon  |
| PinePhone [Manjaro] KDE    | core/pinephone_manjaro_kde    | KDE Variant            |
| PinePhone [Manjaro] Lomiri | core/pinephone_manjaro_lomiri | Lomiri variant         |
| PinePhone [Manjaro] Phosh  | core/pinephone_manjaro_phosh  | Phosh variant          |
| PinePhone [UBPorts]        | core/pinephone_ubports        | Ubuntu-ports (legacy)  |


[KDE Neon]: https://neon.kde.org/
[Manjaro]: https://manjaro.org/
[UBPorts]: https://ubports.com/

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
