# SkiffOS in the Web Browser: V86 Emulator

This configuration package series configures Buildroot to produce a BSP image
for the [V86 Emulator], which can run the system in the web browser.

[V86 Emulator]: https://github.com/copy/v86

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=browser/v86,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will load the ISO into the v86 emulator:

 1. Open https://copy.sh/v86/
 2. Scroll down to "Setup."
 3. Increase the memory size to at least 512MB.
 4. Click "CD image" and select the `rootfs.iso9660` from `images`.
 5. Click "start."

The images directory is located under `workspaces/${SKIFF_WORKSPACE}`.

You can also [run the server] for yourself with Docker.

[run the server]: https://github.com/copy/v86#alternatively-to-build-using-docker
