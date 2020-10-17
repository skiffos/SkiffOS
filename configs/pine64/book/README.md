# Pine64 PineBook

This configuration package `pine64/book` compiles a Skiff base operating system
for the Pine64 PineBook.

References: 

 - https://linux-sunxi.org/Pine_Pinebook
 - https://wiki.pine64.org/index.php/Pinebook
 - https://wiki.pine64.org/index.php/Pinebook_Pro

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/book,core/kde
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../


## KDE Neon

The `core/kde` portion of SKIFF_CONFIG enables "Skiff Core" with
KDE Desktop configured.

