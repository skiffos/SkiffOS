# Skiff Core based on Jellyfin

This configuration runs the official `jellyfin/jellyfin:latest` Docker image as
the Skiff Core container. No SkiffOS-specific Docker image is built.

The default container SSH user is `root`, with shell `/usr/bin/bash`. The Skiff
login is still `core`; Skiff maps `ssh core@...` to the container `root` user.

https://jellyfin.org

## Image source

The image is pulled directly from Docker Hub:

```sh
docker pull jellyfin/jellyfin:latest
```

For local prototyping, edit `/mnt/persist/skiff/core/config.yaml` to use
`jellyfin/jellyfin:latest`, remove the old core container, and run
`systemctl restart skiff-core`.
