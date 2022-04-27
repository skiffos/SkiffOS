# RockPro64

This config layer configures Buildroot to produce a BSP image for the RockPro64.

References: 

- https://wiki.pine64.org/index.php/ROCKPro64
- https://salsa.debian.org/kernel-team/linux/-/tree/master/debian

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

 ```sh
 $ export SKIFF_CONFIG=pine64/rockpro64,core/gentoo
 $ make configure                   # configure the system
 $ make compile                     # build the system
 ```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../

