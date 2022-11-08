# NOTE: mounting these to /mnt/host might not be necessary.
echo "modalai/voxl2: mounting firmware to /mnt/host/firmware"
mkdir -p /mnt/host/firmware || true
/bin/mount \
	-o noexec,nodev,ro \
	-t vfat \
	/dev/disk/by-partlabel/modem_a /mnt/host/firmware || true

echo "modalai/voxl2: mounting bt_firmware to /mnt/host/bt_firmware"
mkdir -p /mnt/host/bt_firmware || true
/bin/mount \
	-o noexec,nodev,ro \
	-t vfat \
	/dev/disk/by-partlabel/bluetooth_a /mnt/host/bt_firmware || true

echo "modalai/voxl2: mounting dsp to /mnt/host/dsp"
mkdir -p /mnt/host/dsp || true
/bin/mount \
	-o noexec,nodev,ro \
	/dev/disk/by-partlabel/dsp_a /mnt/host/dsp || true

# TODO: use a userspace firmware helper instead of copying these files.
# This uses a bit of extra RAM but is an acceptable workaround for now.
cp -r /mnt/host/{firmware,bt_firmware}/image/* /usr/lib/firmware/
