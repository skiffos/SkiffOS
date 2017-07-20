# Skiff in Docker

This directory and [configs/docker/standard](configs/docker/standard) contain files that can be used to run a full SkiffOS system inside a Docker container for simulation and testing.

In the future this setup will be used to demo SkiffOS interactively.

Because systemd and docker both have to run inside a Docker container, starting the container requires some special flags, which are included in the [start.bash](start.bash) file.

## Example

```bash
SKIFF_CONFIG=docker/standard make configure compile # Compile the system
cd ./docker
docker build -t "paralin/skiffos:latest" .          # Build the Docker image.
./start.bash                                        # Start the SkiffOS container.
docker exec -it skiff bash                          # Get a shell in the container.
```
