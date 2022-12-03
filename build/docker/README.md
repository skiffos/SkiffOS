# Build Skiff in Docker

This document describes how to compile Skiff inside a Docker container.

You may want to do this if Buildroot does not run correctly on your machine.

This feature is a bit rough at the moment and will be improved in the future.

### Getting Started

Make sure you have Docker installed on your machine and that it is running. Then use the scripts provided in this folder. They can be run from this folder or the project root but be sure to get the path to the script right if you don't run it from this folder.

To build the Docker container use the build script:

```sh
./build.bash
```

To use the Docker container use the run script:

```sh
./run.bash
```

Then enter the Docker container:

```sh
docker exec -it skiff-build sh
```

And run the following commands (or the version for the build you want) to start the build:

```
$ cd ./skiff
$ make                             # observe status output
$ SKIFF_CONFIG=pi/3 make configure # configure the system
$ make                             # check status again
$ make compile                     # build the system
```
### 2022-12 If the above does not work for you read below

1. Build docker image using Dockerfile.root while inside this directory

```sh
  docker build -f Dockerfile.root -t skiffos-builder .
```

2. Run image as below from SkiffOS github clone root

Replace the environemnt vars below with your needs and run:

```sh
  docker run --rm --privileged -e SKIFF_WORKSPACE=my_workspace -e SKIFF_CONFIG=pi/4,core/alpine --mount type=bind,source=$PWD,target="/home/project"  -it skiffos-builder
```

You should now be inside a fully configured build docker container, enjoy!