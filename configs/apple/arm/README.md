# Apple Macbook (ARM)

This package supports the ARM64 Macbook Pros.

Direct hardware support through [Asahi Linux] will be supported, but has not
been implemented yet. In the meantime, we support running with [UTM] on MacOS.

[Asahi Linux]: https://asahilinux.org/
[UTM]: https://github.com/utmapp/UTM

## Setup

Install UTM on your Mac.

Compile SkiffOS on a Linux host:

```
export SKIFF_CONFIG=apple/arm,skiff/core
make configure compile
```

[TODO] setup instructions

## Compiling on MacOS

Compiling SkiffOS on MacOS is not yet supported.

You can compile it in any Linux environment or VM.

Instructions on how to build using [lima] will be added here soon.

[lima]: https://github.com/lima-vm/lima
