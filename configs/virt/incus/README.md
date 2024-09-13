# Containerized: Incus

This package builds a SkiffOS system for use as a Incus container image.

[Incus](https://linuxcontainers.org/incus/) containers are versatile system containers that, as opposed to application containers like docker, emulate a full init system by default ([more details here](https://linuxcontainers.org/incus/docs/main/explanation/containers_and_vms/)) and are therefore well suited for multi service/container deployments. Incus utilizes the [LXC](https://linuxcontainers.org/) APIs internally and provides a powerful toolset on top of them.

Building and starting the container requires incus to be installed and running on the host and the executing user to be in the `incus-admin` group.

## Example

```bash
SKIFF_CONFIG=virt/incus make configure compile # Compile the system
make cmd/virt/incus/buildimage
make cmd/virt/incus/run
```

Executing a shell in the container:

```sh
$ make cmd/virt/incus/exec
# alternatively
$ incus exec skiff -- sh
```

## Persistence

When using the included command `cmd/virt/incus/run` for creating the container, a persistence volume will be created in the first incus storage pool available and attached to the container. If you want to reset the persistence volume, just delete it, so it will be recreated:

```sh
# You can find the right storage pool with:
# incus storage list -c n -f csv | head -n 1
incus volume delete "${STORAGE_POOL}" skiff-persist
```
