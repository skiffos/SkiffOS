# Skiff Core based on Gentoo

This is a skiff core setup for amd64, arm, arm64 which compiles Gentoo from
source for use within a core container.

The different architectures currently have varying levels of support,
particularly for graphical and desktop packages.

## Pull Pre-built Image

The build process downloads a Gentoo Stage3 and runs portage to upgrade and
install packages.

You can skip the majority of the build process by downloading a pre-built image:

```sh
systemctl stop skiff-core
docker pull skiffos/skiff-core-gentoo:latest
```

Some architectures may not be available in the Docker Hub image.

