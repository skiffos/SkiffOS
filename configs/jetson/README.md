# NVIDIA Linux for Tegra (L4T)

This series of configuration packages targets the NVIDIA Jetson boards.

## Board Compatibility

There are specific packages tuned to each model.

| **Board**    | **Config Package** |
|--------------|--------------------|
| [Jetson AGX] | TODO               |

[Jetson AGX]: https://developer.nvidia.com/embedded/jetson-agx-xavier-developer-kit

## Legacy Board Compatibility

The following boards were discontinued after L4T 32.7.2:

| **Board**     | **Config Package**    |
|---------------|-----------------------|
| [Jetson Nano] | [jetson/nano](./nano) |
| [Jetson TX2]  | [jetson/tx2](./tx2)   |

They are supported by the **linux4tegra-legacy** Buildroot package.

[Jetson Nano]: https://developer.nvidia.com/embedded/jetson-nano-developer-kit
[Jetson TX2]: https://elinux.org/Jetson_TX2

# License Acknowledgment

The NVIDIA Linux4Tegra packages are licensed under the NVIDIA Customer Software
License. SkiffOS does not directly redistribute any parts of the L4T toolkit,
but will download it as a Buildroot package from the NVIDIA servers as part of
the build process. The appropriate licenses can be viewed by triggering the
Buildroot "make legal-info" build step. It is the responsibility of the end user
/ developer to be aware of these terms and follow them accordingly.
