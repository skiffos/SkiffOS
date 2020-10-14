# Skiff Core based on NVIDIA L4T Images

This is a skiff core setup based on the official upstream NVIDIA L4T Docker
Hub distributed images. 

From the documentation at https://ngc.nvidia.com/catalog/containers/nvidia:l4t-base

  l4t-base docker image enables l4t applications to be run in a container using
  the Nvidia Container Runtime on Jetson. It has a subset of packages from the
  l4t rootfs included within. Note that package contents of the l4t-base
  container have changed from the r32.4.2 release (see below for details). The
  platform specific libraries and select device nodes for a particular device
  are mounted by the NVIDIA container runtime into the l4t-base container from
  the underlying host, thereby providing necessary dependencies for l4t
  applications to execute within the container. This approach enables the
  l4t-base container to be shared between various Jetson devices.
  
Skiff core is configured here to mount the requisite paths as bind mounts.

