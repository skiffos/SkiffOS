# Balena Engine Daemon Configuration

This configuration is used as a base for the balena daemon.json.

It will be merged with any files in `resources/balena-engine/daemon.json.d/*.json`
within `SKIFF_CONFIG` packages using `jq` to merge the JSON objects.

To customize this configuration using overrides:

```
cd ./skiffos
mkdir -p ./overrides/resources/balena-engine/daemon.json.d
mv my-daemon.json ./overrides/resources/balena-engine/daemon.json.d/
```
