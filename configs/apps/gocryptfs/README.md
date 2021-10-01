# Gocryptfs
 
> Enables Gocryptfs natively as a Buildroot package.

## Getting Started

Enable the "gocryptfs" configuration layer, i.e:

```sh
$ export SKIFF_CONFIG=pi/4,apps/gocryptfs
$ make configure                   # configure the system
```

The "gocryptfs" binary will be available in the system.

See [gocryptfs docs](https://github.com/rfjakob/gocryptfs) for more info.
