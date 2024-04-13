# Apple Sillicon (ARM)

This package supports the ARM64 Macs.

Direct hardware support through [Asahi Linux] will be supported, but has not
been implemented yet. In the meantime, we support running with [UTM] on MacOS.

[Asahi Linux]: https://asahilinux.org/
[UTM]: https://github.com/utmapp/UTM

## Setup

[Install UTM](https://getutm.app) on your Mac

### Compile on a Linux host

```bash
export SKIFF_CONFIG=apple/arm,skiff/core,virt/qemu
make configure compile
make cmd/apple/arm/make_utm
```
Copy `workspaces/default/SkiffOS.utm` to your Mac

### Compile on Mac (Using Lima)

- [Install Lima](https://github.com/lima-vm/lima?tab=readme-ov-file#getting-started)
- `limactl start https://raw.githubusercontent.com/skiffos/SkiffOS/master/configs/apple/arm/lima.yml --name=skiffos_builder`
- `limactl shell skiffos_builder` to enter the terminal
- `cd ~`
- `git clone https://github.com/skiffos/SkiffOS --depth=1`
- `cd SkiffOS`
- Proceed with usual build sequence:
```bash
export SKIFF_CONFIG=apple/arm,skiff/core,virt/qemu
make configure compile
```
  - For Macs with 16GB RAM or less, reduce the job count during compile: `make compile BR2_JLEVEL=8`
- `make cmd/apple/arm/make_utm` to create the final UTM file
- `cp -r workspaces/default/SkiffOS.utm /opt/skiffos_utm` to send the output to your host OS. The UTM file is now inside skiffos_utm in your Downloads folder!

### Running SkiffOS VM

- Simply double click on the UTM file and press play, everything is preconfigured.
