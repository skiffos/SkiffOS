# Containerized: Docker

This package builds a SkiffOS system for use as a container image.

Example use cases include simulation, testing, or use as a containerized
environment (optionally with Skiff Core and nested containers).

Starting the container requires some additional flags for systemd support, which
are included in the container start script.

## Example

```bash
SKIFF_CONFIG=virt/docker make configure compile # Compile the system
make cmd/virt/docker/buildimage
make cmd/virt/docker/run
```

Executing a shell in the container:

```sh
$ make cmd/virt/docker/exec
# alternatively
$ docker exec -it skiff sh
```
