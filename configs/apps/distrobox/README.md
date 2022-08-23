# Distrobox

> Containerized distribution environments with Docker or Podman.

## Getting Started

[Distrobox] adds the `distrobox` commands using Docker or Podman.

Be sure to also enable either `apps/docker` or `apps/podman`!

[Distrobox]: https://github.com/89luca89/distrobox

Add `apps/distrobox` to your `SKIFF_CONFIG` list, for example:

```sh
SKIFF_CONFIG=virt/qemu,apps/docker,apps/distrobox
make configure
```
