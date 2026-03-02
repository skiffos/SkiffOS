# v86-minimal

Minimal Linux image for the v86 x86 emulator. BusyBox init, stripped
kernel, serial console on ttyS0. Designed for browser-based v86 runtime
with 9p root filesystem.

## Building

```sh
export SKIFF_CONFIG=virt/v86-minimal
make configure
make compile
```

Output: `workspaces/default/images/bzImage` and `rootfs.cpio.lz4`.

## Usage

Boot in v86 with `bzimage_initrd_from_filesystem: true` and 9p root.
