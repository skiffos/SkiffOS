# Toolbx

> Containerized command-line environments with Podman.

## Getting Started

Toolbx (or containers-toolbox) adds the `toolbox` command with Podman container
environments for command-line tools.

[Toolbx]: https://containertoolbx.org/

Add `apps/toolbx` to your `SKIFF_CONFIG` list, for example:

```sh
SKIFF_CONFIG=virt/qemu,apps/toolbx
make configure
```
