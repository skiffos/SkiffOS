# Apple Silicon (ARM64)

This package supports the ARM64 Macs.

Support for booting SkiffOS natively with [Asahi Linux] has not been implemented yet.

[Asahi Linux]: https://asahilinux.org/

In the meantime, we support running with [UTM] on MacOS.

[UTM]: https://github.com/utmapp/UTM

## Compiling

For compiling on MacOS, see [Compile on MacOS].

[Compile on MacOS]: https://github.com/skiffos/SkiffOS?tab=readme-ov-file#compile-on-macos

```bash
export SKIFF_CONFIG=apple/arm,skiff/core,virt/qemu
make configure compile
make cmd/virt/qemu/buildutm
```

Copy `workspaces/default/images/skiffos.utm` to your Mac, on Lima:

```bash
cp workspaces/default/images/skiffos.utm /opt/skiffos-build
```

## Running in UTM

[Install UTM](https://getutm.app) on your MacOS machine.

Run `open ~/skiffos-build` and double-click the skiffos.utm file to start the VM!

