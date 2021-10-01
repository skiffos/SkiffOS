# Docker Compose
 
> Enables Docker Compose natively as a Buildroot package.

## Getting Started

Enable the "docker compose" configuration layer, i.e:

```sh
$ export SKIFF_CONFIG=pi/4,apps/compose
$ make configure                   # configure the system
```

The layer will automatically bring in Docker.
