# Windows Subsystem for Linux

![Screenshot](../../../resources/images/wsl-screenshot.png)

This package adds support for running SkiffOS inside WSL.

WSL2 runs a full Linux kernel in a VM. WSL1 runs the Linux userspace only.

The following example builds WSL with Docker and Skiff Core:

```sh
export SKIFF_CONFIG=virt/wsl,skiff/core
export SKIFF_WORKSPACE=wsl
make configure compile
```

The below instructions cover loading the distribution into a host machine.

This package is compatible with both versions, and uses older kernel headers
(4.4.x) to ensure backwards compatibility. It compiles a more recent (5.6.x)
kernel which can be used if running in WSL2. SkiffOS distributions running in
WSL1 can be upgraded to run in WSL2: `wsl --set-version SkiffOS 2`.

## WSL2

Note: currently WSL2 is only available on Windows Insider builds.

Last updated: January 2021.

To enable WSL2, follow [this guide] summarized here with the below steps:

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl.exe --set-default-version 2
wsl.exe --update
```

[this guide]: https://aka.ms/wsl2-install

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

## Running WSL2 in a Virtualbox Machine

Note: as of January 2021, VirtualBox does not support SLAT pass-through, and the
VM will show the warning "Hyper-V cannot be enabled, the CPU does not support
SLAT" or similar. You will need to run the VM directly with Hyper-V instead of
using VirtualBox to get this to work until SLAT pass-through is implemented.

However, if SLAT pass-through is working:

To enable nested virtualization extensions, required for operating WSL2 inside a
VirtualBox machine, run the following command:

```
VBoxManage modifyvm "My VM Name" --nested-hw-virt on
```

This will enable it even if the box is greyed out in the UI. You may need to go
to the "Windows Features" dialog and enable "Windows Hypervisor Platform."
Windows needs to start-up the Hyper-V subsystem at boot time; if it's not loaded
properly, WSL2 won't work with a vague error about enabling the VM platform.

### Migrating a VirtualBox Machine to Qemu

One possible work-around is to use Qemu instead, which supports SLAT.

Nested virtualization must be enabled in KVM on Intel, check this is "Y":

```
cat /sys/module/kvm_intel/parameters/nested
```

Convert the VM image into the Qemu format:

```
qemu-img convert -f vdi -O raw WindowsVM.vdi QemuWindowsVM.img
```

When importing, use the "use existing disk image" option.

## Running a Windows 10 Qemu/KVM Machine

To test WSL2 on a Linux host, a Windows 10 VM can be run in KVM.

This requires "nested Hyper-V" which requires "SLAT" - second layer address
translation. On Intel CPUs, the QEMU command line must include the +vmx cpu
feature, for example:

```
-cpu SandyBridge,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,+vmx
```

## Known Issues

On WSL 1.0:

 - Older Windows builds: containerd crashes due to a mmap bug
 - systemd does not yet work correctly

