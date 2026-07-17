# SkiffOS — NextThing C.H.I.P. / Pocket C.H.I.P.

SkiffOS support for the **NextThing C.H.I.P.** and **Pocket C.H.I.P.** using
the mainline Linux kernel (6.x) and U-Boot 2024.04. These configs replace the
outdated NTC Linux 4.4 fork with a fully up-to-date software stack.

---

## Config packages

| Package | Use |
|---|---|
| `chip/r8` | C.H.I.P. — Allwinner R8 (sun5i, Cortex-A8, 512 MB RAM) |
| `chip/pocketr8` | Pocket C.H.I.P. — adds 4.3" LCD, TSC2007 touchscreen, backlight |

Both packages depend on `allwinner/r8`, which provides the SoC base
(architecture, kernel, U-Boot, serial console, OTG gadget, audio).

---

## Hardware overview

| Feature | chip/r8 | chip/pocketr8 |
|---|---|---|
| SoC | Allwinner R8 (Cortex-A8, 1 GHz) | same |
| RAM | 512 MB LPDDR3 | same |
| Storage | 4–8 GB internal NAND (MLC, 4 MiB erase blocks) | same |
| WiFi / BT | RTL8723BS (SDIO) | same |
| USB | Micro-USB OTG (MUSB) | same |
| Audio | 3.5 mm headphone + mic | same |
| Display | — | 4.3" RGB panel (480×272) |
| Touch | — | TSC2007 I2C resistive |
| Battery | AXP209 PMIC + LiPo header | same |
| Serial | 3.3 V UART on header (115200) | same |

---

## Build

### 1. Install dependencies (Ubuntu 22.04 / 24.04)

```bash
sudo apt update
sudo apt install -y git build-essential libssl-dev bc bison flex \
  libelf-dev libncurses-dev python3 python3-dev python3-setuptools \
  rsync unzip wget cpio file
```

### 2. Clone and initialise submodules

```bash
git clone https://github.com/skiffos/SkiffOS.git
cd SkiffOS
git submodule update --init
```

### 3. Build

```bash
# For C.H.I.P.:
export SKIFF_CONFIG=chip/r8
make configure
make compile

# For Pocket C.H.I.P.:
export SKIFF_CONFIG=chip/pocketr8
make configure
make compile
```

The build takes **1–3 hours** on first run (cross-toolchain + kernel + packages).
Subsequent `make compile` runs are incremental and much faster.

Output images are written to `workspaces/default/images/`.

> **Note:** The build also compiles patched `mkfs.ubifs` and `ubinize` host
> tools (in `workspaces/default/host/sbin/`) that support the CHIP's 4 MiB
> physical erase blocks. These are required by the flash script and are built
> automatically.

---

## Flashing to NAND

The C.H.I.P. has no SD card slot. The OS is flashed directly to the internal
NAND via USB **FEL mode** using `sunxi-tools`.

### Install flash tools

```bash
sudo apt install -y sunxi-tools u-boot-tools rsync
```

> `mtd-utils` is **not** required from the system package — the flash script
> uses the patched `mkfs.ubifs` and `ubinize` built by Buildroot in
> `workspaces/default/host/sbin/`.

### Enter FEL mode

1. Power the board **off** and disconnect USB.
2. Bridge the **FEL** pin to **GND** with a jumper wire.
   On C.H.I.P. the FEL pin is on the U13 header, one pin away from GND —
   look for the silkscreen label `FEL`.
3. Connect the C.H.I.P. to the host via **Micro-USB**.
4. Verify the host sees it: `lsusb | grep 1f3a:efe8` should return a line.

### Flash

```bash
cd SkiffOS
sudo BUILDROOT_DIR=$(pwd)/workspaces/default \
     SKIFF_CURRENT_CONF_DIR=$(pwd)/configs/chip/r8 \
     bash configs/chip/r8/scripts/flash_nand.sh
```

The script will prompt before writing. Monitor progress on the board's
**UART** at 115200 baud. Flashing takes **3–10 minutes**; do not disconnect
power.

### `--erase-bb` option (worn NAND)

If a board has accumulated bad-block markers from repeated flashing, pass the
`--erase-bb` flag to scrub them:

```bash
sudo BUILDROOT_DIR=$(pwd)/workspaces/default \
     SKIFF_CURRENT_CONF_DIR=$(pwd)/configs/chip/r8 \
     bash configs/chip/r8/scripts/flash_nand.sh --erase-bb
```

Use with care — scrubbing bad-block markers on genuinely worn NAND can cause
data errors.

### NAND layout (after flash)

The CHIP NAND is partitioned as `nand0:4m(spl),4m(spl-backup),4m(uboot),4m(env),-(UBI)` (U-Boot 2024.04 `nand_register()` names devices `nand0`, `nand1`, …):

```
Offset      Size   Partition    Contents
──────────────────────────────────────────────────────────────
0x0000000   4 MiB  spl          U-Boot SPL (primary copy)
0x0400000   4 MiB  spl-backup   U-Boot SPL (redundant copy)
0x0800000   4 MiB  uboot        U-Boot proper (u-boot-dtb.bin)
0x0C00000   4 MiB  env          U-Boot environment
0x1000000   rest   UBI          UBI partition
                     ubi0:rootfs   kernel + squashfs + skiff-init
                     ubi0:persist  user data (autoresize to fill NAND)
```

### NAND physical geometry

The CHIP uses Hynix (H27UCG8T2A) or Toshiba (TC58TEG6DCJTA) MLC NAND with
identical logical geometry visible to the driver:

| Parameter | Value |
|---|---|
| Physical page size | 16 KiB (0x4000) |
| OOB size | 1280 B (0x500) |
| Physical erase block (PEB) | 4 MiB (0x400000) |
| UBIFS LEB | 4,161,536 B (PEB − 2 × page) |

> **Why patched host tools?** Standard `mkfs.ubifs` and `ubinize` from
> `mtd-utils` 2.2.x cap LEB/PEB size at 2 MiB, predating large-page MLC NAND.
> SkiffOS patches these limits to 8 MiB via
> `configs/chip/r8/buildroot_patches/mtd/`.

---

## Serial console

Connect a 3.3 V USB-to-UART adapter to the C.H.I.P. header:

| Header pin | Signal |
|---|---|
| UART-TX | host RX |
| UART-RX | host TX |
| GND | GND |

```bash
screen /dev/ttyUSB0 115200
# or
minicom -D /dev/ttyUSB0 -b 115200
```

---

## OTG / USB gadget networking

The C.H.I.P.'s Micro-USB port is a **MUSB OTG** controller. When the board is
connected to a Linux or macOS host without a USB hub in host mode, it enumerates
as a **USB Ethernet gadget** (`USB_ETH` / CDC ECM).

### Enable on the board

Load the gadget module (if not already auto-loaded):

```bash
modprobe g_ether
```

Assign an IP address:

```bash
ip link set usb0 up
ip addr add 192.168.7.2/24 dev usb0
```

### On the host (Linux)

The host will see a new `usb0` / `enp0sXXX` interface:

```bash
ip link set usb0 up
ip addr add 192.168.7.1/24 dev usb0
ssh root@192.168.7.2
```

### On the host (macOS)

The interface appears as `en#` in System Preferences → Network. Assign
`192.168.7.1/24` manually and SSH to `192.168.7.2`.

> **Tip:** To make the gadget load on every boot, add
> `modprobe g_ether` to `/mnt/persist/skiff/etc/rc.local` or create a systemd
> unit in `/mnt/persist/skiff/etc/systemd/`.

---

## WiFi (RTL8723BS)

The RTL8723BS SDIO WiFi/BT chip is supported via the staging driver
(`CONFIG_RTL8723BS=m`). Use **NetworkManager** to connect:

```bash
# Scan and connect (interactive TUI)
nmtui

# Or command-line
nmcli device wifi list
nmcli device wifi connect "MyNetwork" password "MyPassword"
```

Check interface status:

```bash
ip link show wlan0
nmcli connection show
```

WiFi connections are persisted to `/mnt/persist/skiff/connections/` and
reconnect automatically on reboot.

---

## Bluetooth (RTL8723BS)

The RTL8723BS Bluetooth firmware (`rtl_bt/rtl8723bs_fw.bin`) is included via
`linux-firmware`. The kernel loads it automatically when the BT interface is
brought up.

```bash
bluetoothctl
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# scan on
[bluetooth]# pair <MAC>
[bluetooth]# connect <MAC>
[bluetooth]# quit
```

---

## Audio

The AXP209 PMIC and sun4i analog codec provide headphone output and microphone
input via the 3.5 mm jack.

```bash
# List ALSA devices
aplay -l

# Play a file
aplay -D hw:0,0 audio.wav

# Adjust volume
alsamixer
```

---

## Battery and power (AXP209 PMIC)

The AXP209 PMIC manages battery charging, fuel gauge, and the power button.
It exposes these via the Linux power-supply class:

```bash
# Battery status
cat /sys/class/power_supply/axp20x-battery/status
cat /sys/class/power_supply/axp20x-battery/capacity

# AC adapter status
cat /sys/class/power_supply/axp20x-ac/online
```

---

## Pocket C.H.I.P. extras

### Display

The 4.3" RGB panel (480×272) is driven by the sun4i display engine. The
framebuffer device is `/dev/fb0`. Console output is shown on the panel.

> The R8 SoC has no HDMI hardware; HDMI is disabled in U-Boot
> (`# CONFIG_VIDEO_HDMI is not set`) to prevent hangs during init.

### Touchscreen (TSC2007)

The resistive touchscreen uses the `tsc2007` I2C driver and exposes a standard
`evdev` input device:

```bash
# Find the input device
ls /dev/input/
evtest /dev/input/event0    # replace with the correct event node
```

Calibrate with `ts_calibrate` (from the `tslib` package if included in your
core config).

---

## Persist storage

All user data, SSH keys, NetworkManager connections, and configuration
overrides are stored on the **`ubi0:persist`** UBI volume, mounted at
`/mnt/persist`. This volume uses UBIFS and expands automatically to fill
all available NAND on first boot.

```
/mnt/persist/skiff/keys/          ← SSH public keys (*.pub)
/mnt/persist/skiff/connections/   ← NetworkManager keyfiles
/mnt/persist/skiff/hostname       ← board hostname
/mnt/persist/skiff/etc/           ← /etc overrides (applied on boot)
```

To add an SSH key for passwordless login:

```bash
# From the host
scp ~/.ssh/id_rsa.pub root@192.168.7.2:/mnt/persist/skiff/keys/
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `lsusb` shows nothing in FEL | FEL pin not bridged / wrong pin | Double-check FEL–GND jumper |
| Flash hangs at "Waiting 1s" | Board not responding after SPL | Retry; ensure USB cable supports data |
| Boot stops at U-Boot prompt | Bad NAND write / incomplete flash | Reflash; try `--erase-bb` |
| `ERROR: Buildroot host-mtd tools not found` | Build not run yet | Run `SKIFF_CONFIG=chip/r8 make configure compile` first |
| `too large LEB size` / `too high physical eraseblock size` | Using system mtd-utils instead of Buildroot tools | Do not install `mtd-utils` system-wide; let the script use Buildroot's patched binaries |
| No WiFi interface (`wlan0`) | `rtl8723bs` module not loaded | `modprobe rtl8723bs`; check `dmesg` |
| No BT interface | Firmware not found | Verify `rtl_bt/rtl8723bs_fw.bin` is in `/lib/firmware/` |
| Touchscreen not responding (Pocket) | Wrong input event node | Run `evtest` to identify correct `/dev/input/event#` |
| Image too large for FEL | Core config too heavy (>448 MiB) | Use a lighter `core/` config |
