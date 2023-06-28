# Docker Daemon Configuration

This configuration is used as a base for the docker daemon.json.

It will be merged with any files in `resources/docker/daemon.json.d/*.json`
within `SKIFF_CONFIG` packages using `jq` to merge the JSON objects.

To customize this configuration using overrides:

```
cd ./skiffos
mkdir -p ./overrides/resources/docker/daemon.json.d
mv my-daemon.json ./overrides/resources/docker/daemon.json.d/
```
