# Build in Docker

You may want to build SkiffOS in a docker container if Buildroot does not run
correctly on your machine. Some distributions have library issues which cause
Buildroot builds to not work properly.

### Getting Started

Be sure to have Docker installed and running on your build machine.

To build the Docker container use the build script:

```sh
./build.bash
```

To use the Docker container use the run script:

```sh
./run.bash
```

The script optionally accepts a custom container name & command:

```sh
./run.bash mycontainer make compile
```

Then enter the Docker container:

```sh
docker exec -it skiffos-build bash
```

And run the following commands (or the version for the build you want) to start the build:

```
$ cd ./skiff
$ make                             # observe status output
$ SKIFF_CONFIG=pi/3 make configure # configure the system
$ make                             # check status again
$ make compile                     # build the system
```
