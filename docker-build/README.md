# Build Skiff in Docker

This document describes how to compile Skiff inside a Docker container.

You may want to do this if Buildroot does not run correctly on your machine.

This feature is a bit rough at the moment and will be improved in the future.

### Getting Started

All commands are run in the Skiff root.

Build the working environment:

```sh
docker build -t "skiff/build:latest" ./docker-build
```

Start the container:

```sh
docker run -d \
	--name=skiff-build \
    -v $(pwd):/home/buildroot/skiff \
	--restart=on-failure \
	skiff/build:latest /bin/sleep 9999999
```

Enter the container:

```sh
docker exec -it skiff-build sh

$ cd ./buildroot
$ make configure compile
```
