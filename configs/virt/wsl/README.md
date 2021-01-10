# Windows Subsystem for Linux

This configuration package adds support for running as a WSL Guest to SkiffOS.

WSL2 runs a full Linux kernel in a VM. WSL1 runs the Linux userspace only.

This package is compatible with both, and uses older kernel headers (4.4.x) to
ensure backwards compatibility, but compiles a more recent (5.6.x) kernel, which
containers can be compiled against to take full advantage of the new features
(if running in WSL2). SkiffOS distributions running in WSL1 can be upgraded to
run in WSL2 without a full re-install using the standard process.

The following example builds WSL with Docker and Skiff Core:

```sh
export SKIFF_CONFIG=virt/wsl,skiff/core
export SKIFF_WORKSPACE=wsl
make configure compile
```

The below instructions cover loading the distribution into a host machine.

## WSL2

Note: currently WSL2 is only available on Windows Insider builds.

Last updated: January 2021.

To enable WSL2, follow [this guide] summarized here with the below steps:

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl.exe --set-default-version 2
```

[this guide]: https://www.omgubuntu.co.uk/how-to-install-wsl2-on-windows-10

You can then import the SkiffOS build output `rootfs.tar.gz`:

```
# import, creating rootfs file at storage path
wsl.exe --import SkiffOS C:\Path\To\Storage C:\Path\To\rootfs.tar.gz
# list
wsl.exe --list --all -v
# delete all files for distro
wsl.exe -d SkiffOS
```

## WSL1 (Legacy)

Download the WSL distro launcher for SkiffOS:

```sh
git clone https://github.com/SkiffOS/WSL-DistroLauncher
cd WSL-DistroLauncher/x64
cp ../../../skiff/workspaces/wsl/images/rootfs.tar.gz ./install.tar.gz
```

You will need a Windows machine to compile the Appx containing SkiffOS with a
self-signed certificate. You also will need to make sure that the "developer"
options are enabled so that "side-loading" apps from files is allowed.

Open `SkiffOS-Appx/SkiffOS.appxmanifest` with Visual Studio. If you do not see a
configuration GUI, you likely will need to install the Visual Studio extra
features "Universal Windows Platform C++ tools" and "Windows 10 SDK for UWP."

Select "Packaging" and "Choose Certificate" and then "Create."

To sideload your appx on your machine for testing, right-click on the "Solution
(DistroLauncher)" in the Solution Explorer and click "Deploy Solution". This
should build the project and sideload it automatically for testing. To
unregister the project, run "wslconfig.exe /unregister".

To compile a release image: Close Visual Studio and open the "Developer Prompt
for Visual Studio." Use `cd` to change directories to the WSL-DistroLauncher
project. Run the "build.bat" script. Note: this is generally less reliable than
running the Visual Studio deploy approach.
