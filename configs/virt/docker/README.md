# Skiff in Docker

This config is designed to run a full SkiffOS system inside a Docker container.

Example use cases include simulation, testing, or use as a containerized
environment (optionally with Skiff Core).

Because systemd and docker both have to run inside a Docker container, starting
the container requires some special flags, which are included in the container
start script.

## Example

```bash
SKIFF_CONFIG=virt/docker make configure compile # Compile the system
make cmd/virt/docker/build-image
make cmd/virt/docker/run
```

Executing a shell in the container:

```sh
$ make cmd/virt/docker/exec
# alternatively
$ docker exec -it skiff sh
```

