# Pine64 H64

This configuration package `pine64/h64` compiles a Skiff base operating system
for the Pine64 "H64" board.

References: 

 - https://www.pine64.org/pine-h64-ver-b/

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/h64,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../

