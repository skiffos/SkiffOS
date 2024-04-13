#!/bin/bash
set -eo pipefail

# Because UTM is an Apple-only platform, and we typically build SkiffOS on (a) Linux (container),
# we use a Bash script to strictly follow the UTM format, which can be easily loaded onto any Mac (or iOS, if you like to live on the edge)

IMAGES_DIR=$BUILDROOT_DIR/images
SKIFFOS_UTM_DIR=$BUILDROOT_DIR/SkiffOS.utm
ROOTFS_DISK=$SKIFFOS_UTM_DIR/Data/persist.qcow2

if [ -z "${ROOTFS_MAX_SIZE}" ]; then
  ROOTFS_MAX_SIZE="32G"
fi

if [ ! -d "$SKIFFOS_UTM_DIR" ]; then
    mkdir -p "$SKIFFOS_UTM_DIR/Data"
fi

cd "$SKIFFOS_UTM_DIR"

cp "$ROOT_DIR/resources/images/skiff-icon.png" "Data/skiff-icon.png"
cp "$IMAGES_DIR/Image" "Data/Image"
cp "$IMAGES_DIR/rootfs.cpio.lz4" "Data/rootfs.cpio.lz4"

if [ ! -f ${ROOTFS_DISK} ]; then
    # Sparse/dynamically allocated image
    qemu-img create -f qcow2 ${ROOTFS_DISK} ${ROOTFS_MAX_SIZE}
fi

# Bash version ported from: https://github.com/utmapp/UTM/blob/13664282a2a9fb239f62c5777cb45cabcce29fae/Configuration/UTMConfiguration%2BNetworking.m#L75-L85
function generate_mac_address() {
    local mac=""
    for i in {1..6}; do
        local byte=$((RANDOM % 256))
        if [[ $i -eq 1 ]]; then
            byte=$((byte & 0xFC | 0x2))
        fi
        mac+=$(printf "%02X" $byte)
        if [[ $i -lt 6 ]]; then
            mac+=":"
        fi
    done
    echo "$mac"
}

cat > config.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Backend</key>
    <string>QEMU</string>
    <key>ConfigurationVersion</key>
    <integer>4</integer>
    <key>Display</key>
    <array>
        <dict>
            <key>DownscalingFilter</key>
            <string>Linear</string>
            <key>DynamicResolution</key>
            <true/>
            <key>Hardware</key>
            <string>virtio-gpu-pci</string>
            <key>NativeResolution</key>
            <false/>
            <key>UpscalingFilter</key>
            <string>Nearest</string>
        </dict>
    </array>
    <key>Drive</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>`cat /proc/sys/kernel/random/uuid`</string>
            <key>ImageName</key>
            <string>Image</string>
            <key>ImageType</key>
            <string>LinuxKernel</string>
            <key>Interface</key>
            <string>None</string>
            <key>InterfaceVersion</key>
            <integer>1</integer>
            <key>ReadOnly</key>
            <false/>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>`cat /proc/sys/kernel/random/uuid`</string>
            <key>ImageName</key>
            <string>rootfs.cpio.lz4</string>
            <key>ImageType</key>
            <string>LinuxInitrd</string>
            <key>Interface</key>
            <string>None</string>
            <key>InterfaceVersion</key>
            <integer>1</integer>
            <key>ReadOnly</key>
            <false/>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>`cat /proc/sys/kernel/random/uuid`</string>
            <key>ImageName</key>
            <string>persist.qcow2</string>
            <key>ImageType</key>
            <string>Disk</string>
            <key>Interface</key>
            <string>VirtIO</string>
            <key>InterfaceVersion</key>
            <integer>1</integer>
            <key>ReadOnly</key>
            <false/>
        </dict>
    </array>
    <key>Information</key>
    <dict>
        <key>Icon</key>
        <string>skiff-icon.png</string>
        <key>IconCustom</key>
        <true/>
        <key>Name</key>
        <string>SkiffOS</string>
        <key>UUID</key>
        <string>`cat /proc/sys/kernel/random/uuid`</string>
    </dict>
    <key>Input</key>
    <dict>
        <key>MaximumUsbShare</key>
        <integer>3</integer>
        <key>UsbBusSupport</key>
        <string>3.0</string>
        <key>UsbSharing</key>
        <false/>
    </dict>
    <key>Network</key>
    <array>
        <dict>
            <key>Hardware</key>
            <string>virtio-net-pci</string>
            <key>IsolateFromHost</key>
            <false/>
            <key>MacAddress</key>
            <string>`generate_mac_address`</string>
            <key>Mode</key>
            <string>Shared</string>
            <key>PortForward</key>
            <array/>
        </dict>
    </array>
    <key>QEMU</key>
    <dict>
        <key>AdditionalArguments</key>
        <array>
            <string>-append</string>
            <string>"root=/dev/ram0 ro net.ifnames=0"</string>
        </array>
        <key>BalloonDevice</key>
        <false/>
        <key>DebugLog</key>
        <false/>
        <key>Hypervisor</key>
        <true/>
        <key>PS2Controller</key>
        <false/>
        <key>RNGDevice</key>
        <true/>
        <key>RTCLocalTime</key>
        <false/>
        <key>TPMDevice</key>
        <false/>
        <key>TSO</key>
        <false/>
        <key>UEFIBoot</key>
        <true/>
    </dict>
    <key>Serial</key>
    <array>
        <dict>
            <key>Mode</key>
            <string>Terminal</string>
            <key>Target</key>
            <string>Auto</string>
            <key>Terminal</key>
            <dict>
                <key>BackgroundColor</key>
                <string>#000000</string>
                <key>CursorBlink</key>
                <true/>
                <key>Font</key>
                <string>Menlo</string>
                <key>FontSize</key>
                <integer>12</integer>
                <key>ForegroundColor</key>
                <string>#ffffff</string>
            </dict>
        </dict>
    </array>
    <key>Sharing</key>
    <dict>
        <key>ClipboardSharing</key>
        <true/>
        <key>DirectoryShareMode</key>
        <string>VirtFS</string>
        <key>DirectoryShareReadOnly</key>
        <false/>
    </dict>
    <key>Sound</key>
    <array>
        <dict>
            <key>Hardware</key>
            <string>intel-hda</string>
        </dict>
    </array>
    <key>System</key>
    <dict>
        <key>Architecture</key>
        <string>aarch64</string>
        <key>CPU</key>
        <string>default</string>
        <key>CPUCount</key>
        <integer>0</integer>
        <key>CPUFlagsAdd</key>
        <array/>
        <key>CPUFlagsRemove</key>
        <array/>
        <key>ForceMulticore</key>
        <false/>
        <key>JITCacheSize</key>
        <integer>0</integer>
        <key>MemorySize</key>
        <integer>4096</integer>
        <key>Target</key>
        <string>virt</string>
    </dict>
</dict>
</plist>
EOF
