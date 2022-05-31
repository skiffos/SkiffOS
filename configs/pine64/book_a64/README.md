# Pine64 PineBook (A64)

This configuration package `pine64/book_a64` compiles Skiff for the A64-based
PineBook (original, not pro).

The PineBook Pro configuration is in [pine64/book](../book).

References: 

 - https://linux-sunxi.org/Pine_Pinebook
 - https://wiki.pine64.org/index.php/Pinebook

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/book_a64,core/pinebook_gentoo
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../

## XFCE with NixOS

Add `core/nixos_xfce` to SKIFF_CONFIG to enable "Skiff Core" with XFCE Desktop
configured.

