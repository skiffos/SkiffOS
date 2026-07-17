#!/bin/bash
# Flash SkiffOS to C.H.I.P. internal NAND via USB FEL mode.
#
# Works on BOTH Hynix and Toshiba NAND variants (MLC, 4 MiB physical erase
# blocks).  The CHIP-specific "nand slc-mode" command is NOT available in
# mainline U-Boot 2024.04; all UBI parameters use the full MLC PEB size.
#
# Prerequisites (host):
#   sudo apt install sunxi-tools u-boot-tools mtd-utils
#
# To enter FEL mode on the CHIP:
#   1. Power the board off and disconnect USB.
#   2. Bridge the FEL pin to GND with a jumper wire.
#      (On CHIP: FEL is on the header next to the USB port, one pin
#       from GND — see silkscreen label "FEL".)
#   3. Connect the CHIP to this host via micro-USB.
#   4. Run this script as root.
#
# Usage:
#   sudo BUILDROOT_DIR=/path/to/buildroot/output \
#        SKIFF_CURRENT_CONF_DIR=/path/to/configs/chip/r8 \
#        bash flash_nand.sh [--erase-bb]
#
# Options:
#   --erase-bb   Use "nand scrub" instead of "nand erase" to also
#                clear bad-block markers. Use with care on worn NAND.
#
# ── NAND layout (physical) ──────────────────────────────────────────
#  0x0000000 – 0x0800000  (8 × 1 MiB)   SPL copies
#  0x0800000 – 0x1000000  (8 MiB)        U-Boot
#  0x1000000 – end        (~7.9 GiB)     UBI partition (rootfs)
#
# ── CHIP NAND parameters (MLC, no SLC mode) ───────────────────────
#  Physical page:            16 KiB  (0x4000)
#  Physical erase block:      4 MiB  (0x400000)
#  UBIFS LEB:      4 MiB – 2×16 KiB = 4 161 536 bytes
# ───────────────────────────────────────────────────────────────────

set -e

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)."
  exit 1
fi

NAND_ERASE_BB=false
if [ "$1" = "--erase-bb" ]; then
  NAND_ERASE_BB=true
fi

# --- required tools ---
for tool in sunxi-fel mkimage rsync; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' not found."
    echo "Install missing tools: sudo apt install sunxi-tools u-boot-tools mtd-utils rsync"
    exit 1
  fi
done

FEL="${FEL:-sunxi-fel}"

if [ -z "$BUILDROOT_DIR" ]; then
  echo "ERROR: BUILDROOT_DIR is not set."
  echo "Set it to the Buildroot output directory (contains images/)."
  exit 1
fi

if [ -z "$SKIFF_CURRENT_CONF_DIR" ]; then
  echo "ERROR: SKIFF_CURRENT_CONF_DIR is not set."
  exit 1
fi

# The CHIP NAND has 4 MiB physical erase blocks → UBI LEB ~4 MiB, which
# exceeds the 2 MiB cap in the system mkfs.ubifs and ubinize.  Use the
# Buildroot-built host-mtd binaries (patched to 8 MiB); error out if absent.
BR_MKFS_UBIFS="${BUILDROOT_DIR}/host/sbin/mkfs.ubifs"
BR_UBINIZE="${BUILDROOT_DIR}/host/sbin/ubinize"
if [ -x "$BR_MKFS_UBIFS" ] && [ -x "$BR_UBINIZE" ]; then
  MKFS_UBIFS="$BR_MKFS_UBIFS"
  UBINIZE="$BR_UBINIZE"
  echo "Using Buildroot host-mtd tools: $MKFS_UBIFS, $UBINIZE"
else
  echo "ERROR: Buildroot host-mtd tools not found (expected in ${BUILDROOT_DIR}/host/sbin/)."
  echo "  Build SkiffOS once to compile the patched versions:"
  echo "    SKIFF_CONFIG=chip/r8 make configure compile"
  exit 1
fi

IMAGES_DIR="${BUILDROOT_DIR}/images"

for f in sunxi-spl.bin u-boot-dtb.bin zImage; do
  if [ ! -f "$IMAGES_DIR/$f" ]; then
    echo "ERROR: $f not found in $IMAGES_DIR — run 'make compile' first."
    exit 1
  fi
done

if [ ! -f "$IMAGES_DIR/rootfs.squashfs" ]; then
  echo "ERROR: rootfs.squashfs not found in $IMAGES_DIR — run 'make compile' first."
  exit 1
fi

# ── memory addresses for FEL upload ──
# DRAM: 0x40000000 – 0x60000000 (512 MiB on CHIP)
#
# Layout (must not overlap):
#   0x43000000  SPL          (tiny, < 64 KiB)
#   0x43100000  U-Boot script (< 16 KiB)
#   0x4a000000  U-Boot       (< 4 MiB; TEXT_BASE = 0x4a000000)
#   0x50000000  UBI image    (up to ~160 MiB → ends at ~0x5A000000)
#   ~0x5E000000 U-Boot relocation area (reserved by U-Boot at top of DRAM)
#
# IMPORTANT: UBI was previously at 0x44000000, which overlaps U-Boot at
# 0x4a000000 (a 148 MiB UBI image reaches 0x4D400000).  U-Boot was silently
# overwritten in DRAM before execution, causing an instant silent crash.
SPL_MEM_ADDR=0x43000000
UBOOT_MEM_ADDR=0x4a000000
UBOOT_SCRIPT_MEM_ADDR=0x43100000
UBI_MEM_ADDR=0x50000000   # above U-Boot; 148 MiB ends at ~0x59400000 < 0x60000000

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

PADDED_SPL="$TMPDIR/sunxi-padded-spl"
PADDED_UBOOT="$TMPDIR/padded-uboot"
# Padded size is calculated dynamically below from the actual binary size,
# rounded up to the NAND page size (16 KiB = 0x4000).
PADDED_UBOOT_SIZE=0
UBOOT_SCRIPT_SRC="$TMPDIR/uboot.cmds"
UBOOT_SCRIPT="$TMPDIR/uboot.scr"

# ── Progress helpers ───────────────────────────────────────────────
STEP=0
TOTAL_STEPS=5

step() {
  STEP=$(( STEP + 1 ))
  echo ""
  echo "── Step ${STEP}/${TOTAL_STEPS}: $* ──"
  _STEP_START=$(date +%s)
}

step_done() {
  local elapsed=$(( $(date +%s) - _STEP_START ))
  printf "   done in %ds\n" "$elapsed"
}

# Run a command silently, showing a spinner and elapsed time.
# Usage: run_spinner "label" cmd [args...]
run_spinner() {
  local label="$1"; shift
  local pid i rc
  local frames='|/-\'
  local out_file
  out_file=$(mktemp)
  printf "   %s ... " "$label"
  "$@" >"$out_file" 2>&1 &
  pid=$!
  i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r   %s ... %s" "$label" "${frames:$(( i % 4 )):1}"
    i=$(( i + 1 ))
    sleep 0.15
  done
  if wait "$pid"; then
    printf "\r   %s ... done\n" "$label"
    rm -f "$out_file"
  else
    rc=$?
    printf "\r   %s ... FAILED\n" "$label"
    cat "$out_file" >&2
    rm -f "$out_file"
    return $rc
  fi
}

fel_write() {
  local addr="$1" file="$2"
  local size_human
  size_human=$(du -sh "$file" | cut -f1)
  printf "   %-30s  %s\n" "$(basename "$file")" "$size_human"
  $FEL write "$addr" "$file"
}

# ── Step 1: prepare SPL (BROM boot0 format) ────────────────────────
# The BROM reads SPL with its OWN NAND layout (boot0): 4096 usable bytes
# per 16 KiB page, BCH-64/1024 ECC, scrambled with fixed per-page seeds.
# A plain `nand write` (standard MTD ECC layout) produces an SPL the BROM
# cannot decode -- the board silently falls back to FEL mode on cold boot.
# Build a pre-encoded raw image (data+OOB) and flash it with `nand write.raw`.
step "Prepare SPL (boot0 image)"
# U-Boot's build system already generates the BROM-readable image
# (spl/sunxi-spl-with-ecc.bin) using tools/sunxi-spl-image-builder with
# the board's Kconfig values: -c 64/1024 -p 16384 -o 1664 -u 1024
# -e 0x400000 -s -b.  Note usable=1024: the A13 BROM reads only 1 KiB
# of data per 16 KiB page.  See u-boot board/sunxi/README.nand.
SPL_WITH_ECC=""
for cand in \
  "$IMAGES_DIR/sunxi-spl-with-ecc.bin" \
  "$BUILDROOT_DIR"/build/uboot-*/spl/sunxi-spl-with-ecc.bin; do
  [ -f "$cand" ] && { SPL_WITH_ECC="$cand"; break; }
done
if [ -z "$SPL_WITH_ECC" ]; then
  echo "ERROR: sunxi-spl-with-ecc.bin not found (rebuild U-Boot with CONFIG_MTD_RAW_NAND=y)."
  exit 1
fi
cp "$SPL_WITH_ECC" "$PADDED_SPL"
RAW_SPL_BYTES=$(stat --printf="%s" "$PADDED_SPL")
# write.raw takes a PAGE count; each raw page is page+oob = 16384+1664.
SPL_PAGE_COUNT=$(printf "0x%x" $(( RAW_SPL_BYTES / (16384 + 1664) )))
PADDED_SPL_SIZE=$(printf "0x%x" "$RAW_SPL_BYTES")
echo "   SPL boot0 image: $SPL_WITH_ECC"
echo "   raw size: $PADDED_SPL_SIZE ($RAW_SPL_BYTES bytes, $SPL_PAGE_COUNT pages)"
step_done

# ── Step 2: prepare U-Boot ────────────────────────────────────────
step "Prepare U-Boot"
UBOOT="$IMAGES_DIR/u-boot-dtb.bin"
# Copy U-Boot, rounding the last block up to a full 16 KiB NAND page.
dd if="$UBOOT" of="$PADDED_UBOOT" bs=16k conv=sync status=progress 2>&1 | sed 's/^/   /'
# Use the actual (post-copy, page-aligned) file size — no fixed cap.
PADDED_UBOOT_SIZE=$(stat --printf="%s" "$PADDED_UBOOT" | xargs printf "0x%x")
echo "   U-Boot padded size: $PADDED_UBOOT_SIZE ($(stat --printf="%s" "$PADDED_UBOOT") bytes)"
step_done

# ── Step 3: build UBIFS + UBI image ─────────────────────────────────
# The UBI volume mirrors the SD card /boot/ layout so skiff-init works.
step "Build UBI image"

NAND_ROOT="$TMPDIR/nand-root"
mkdir -p "$NAND_ROOT/boot/skiff-init"
# Pre-create the mountpoint/scaffold dirs skiff-init expects.  Without /dev
# in the UBIFS root the kernel devtmpfs automount fails
# ("devtmpfs: error mounting -2") and skiff-init has no /dev/kmsg to log to.
mkdir -p "$NAND_ROOT"/{dev,proc,sys,run,etc} \
         "$NAND_ROOT"/mnt/{boot,persist,host} \
         "$NAND_ROOT"/skiff-overlays/{image,system,system-tmp}

echo "   Copying boot files..."
cp "$IMAGES_DIR/zImage"           "$NAND_ROOT/boot/"
cp "$IMAGES_DIR"/*.dtb            "$NAND_ROOT/boot/" 2>/dev/null || true
cp "$IMAGES_DIR/rootfs.squashfs"  "$NAND_ROOT/boot/"
cp "$IMAGES_DIR/skiff-release"    "$NAND_ROOT/boot/" 2>/dev/null || true
rsync -r "$IMAGES_DIR/skiff-init/" "$NAND_ROOT/boot/skiff-init/"

# Compile NAND-specific U-Boot boot script
NAND_BOOT_TXT="${SKIFF_CURRENT_CONF_DIR}/resources/nand-boot/boot.txt"
if [ -f "$NAND_BOOT_TXT" ]; then
  cp "$NAND_BOOT_TXT" "$NAND_ROOT/boot/boot.txt"
  mkimage -A arm -C none -T script -n 'SkiffOS NAND' \
    -d "$NAND_ROOT/boot/boot.txt" "$NAND_ROOT/boot/boot.scr" &>/dev/null
fi

ROOTFS_SIZE=$(du -sb "$NAND_ROOT" | awk '{print $1}')
echo "   Boot tree size:  $(( ROOTFS_SIZE / 1024 / 1024 )) MiB"

MAX_FEL_SIZE=$(( 448 * 1024 * 1024 ))
if [ "$ROOTFS_SIZE" -gt "$MAX_FEL_SIZE" ]; then
  echo ""
  echo "   WARNING: image (~$(( ROOTFS_SIZE / 1024 / 1024 )) MiB) may exceed"
  echo "            CHIP's available RAM for FEL upload (~448 MiB)."
  echo "            Consider using a smaller core config."
  echo ""
fi

# Seed a NetworkManager profile for the USB ethernet gadget (g_ether/usb0)
# so the board is reachable over the OTG cable on first boot:
#   host: 10.42.0.1/24  <-->  board: 10.42.0.2/24   (ssh root@10.42.0.2)
# NOTE: on chip/r8 skiff-init uses ROOT_AS_PERSIST — /mnt/persist is the
# rootfs UBIFS volume, NOT the separate "persist" UBI volume.  The
# connections dir mount-all.sh reads is therefore <rootfs-ubifs>/skiff/
# connections, i.e. NAND_ROOT here.
mkdir -p "$NAND_ROOT/skiff/connections"
cat > "$NAND_ROOT/skiff/connections/usb-gadget.nmconnection" << 'NMEOF'
[connection]
id=usb-gadget
type=ethernet
interface-name=usb0
autoconnect=true

[ipv4]
method=manual
address1=10.42.0.2/24

[ipv6]
method=link-local
NMEOF
chmod 600 "$NAND_ROOT/skiff/connections/usb-gadget.nmconnection"

ROOTFS_UBIFS="$TMPDIR/chip-rootfs.ubifs"
run_spinner "Building rootfs UBIFS" \
  "$MKFS_UBIFS" \
    --min-io-size=16384 \
    --leb-size=4161536  \
    --max-leb-cnt=4096  \
    --root="$NAND_ROOT"  \
    --output="$ROOTFS_UBIFS"

PERSIST_DIR="$TMPDIR/persist-root"
mkdir -p "$PERSIST_DIR"
PERSIST_UBIFS="$TMPDIR/chip-persist.ubifs"
run_spinner "Building persist UBIFS" \
  "$MKFS_UBIFS" \
    --min-io-size=16384 \
    --leb-size=4161536  \
    --max-leb-cnt=4096  \
    --root="$PERSIST_DIR" \
    --output="$PERSIST_UBIFS"

# Give the rootfs volume slack beyond the image size.  Without this the
# UBIFS is 100% full at first boot and every mkdir/write fails (ENOSPC),
# which broke skiff-init's runtime mountpoint creation.
ROOTFS_VOL_SIZE=$(( $(stat --printf="%s" "$ROOTFS_UBIFS") + 128 * 1024 * 1024 ))

UBINIZE_CFG="$TMPDIR/ubinize.cfg"
cat > "$UBINIZE_CFG" << 'EOF'
[rootfs]
mode=ubi
image=ROOTFS_UBIFS_PLACEHOLDER
vol_id=0
vol_type=dynamic
vol_name=rootfs
vol_size=ROOTFS_VOL_SIZE_PLACEHOLDER

[persist]
mode=ubi
image=PERSIST_UBIFS_PLACEHOLDER
vol_id=1
vol_type=dynamic
vol_name=persist
vol_flags=autoresize
EOF
sed -i "s|ROOTFS_UBIFS_PLACEHOLDER|$ROOTFS_UBIFS|" "$UBINIZE_CFG"
sed -i "s|ROOTFS_VOL_SIZE_PLACEHOLDER|$ROOTFS_VOL_SIZE|" "$UBINIZE_CFG"
sed -i "s|PERSIST_UBIFS_PLACEHOLDER|$PERSIST_UBIFS|" "$UBINIZE_CFG"

UBI_IMG="$TMPDIR/chip-nand.ubi"
run_spinner "Combining into UBI image" \
  "$UBINIZE" \
    --output="$UBI_IMG"  \
    --min-io-size=16384  \
    --peb-size=4194304   \
    --sub-page-size=16384 \
    "$UBINIZE_CFG"

UBI_SIZE=$(stat --printf="%s" "$UBI_IMG" | xargs printf "0x%08x")
echo "   UBI image size: $UBI_SIZE ($(( $(stat --printf="%s" "$UBI_IMG") / 1024 / 1024 )) MiB)"
step_done

# ── Step 4: build U-Boot flash script ────────────────────────────────
step "Prepare U-Boot NAND flash script"
# Select DTB from the SkiffOS config being flashed, not by file presence
# (both DTBs may exist in images/ from prior builds of the other variant).
case "${SKIFF_CURRENT_CONF_DIR}" in
  *pocketr8*) FDTFILE="sun5i-r8-pocketchip.dtb" ;;
  *)          FDTFILE="sun5i-r8-chip.dtb" ;;
esac

{
  echo "echo '=== SkiffOS NAND flash script start ==='"

  # Erase entire NAND.  --erase-bb uses scrub to also clear bad-block markers.
  echo "echo 'Step 1: erasing NAND...'"
  if [ "$NAND_ERASE_BB" = true ]; then
    echo "nand scrub.chip -y"
  else
    echo "nand erase.chip"
  fi
  echo "echo 'Step 1: NAND erase done'"

  # Write SPL — two copies, one per 4 MiB erase block (spl@0, spl-backup@4m).
  # The image is pre-encoded in BROM boot0 format (data+OOB, BCH-64/1024,
  # scrambled), so it MUST be written raw — write.raw takes a PAGE count.
  echo "echo 'Step 2: writing SPL (boot0 raw)...'"
  echo "nand write.raw.noverify ${SPL_MEM_ADDR} 0x0       ${SPL_PAGE_COUNT}"
  echo "nand write.raw.noverify ${SPL_MEM_ADDR} 0x400000  ${SPL_PAGE_COUNT}"
  echo "echo 'Step 2: SPL write done'"

  # Write U-Boot at 8 MiB (uboot partition).
  echo "echo 'Step 3: writing U-Boot...'"
  echo "nand write ${UBOOT_MEM_ADDR} 0x800000 ${PADDED_UBOOT_SIZE}"
  echo "echo 'Step 3: U-Boot write done'"

  # Write UBI at 16 MiB (after spl 4m + spl-backup 4m + uboot 4m + env 4m).
  # trimffs skips trailing 0xFF pages to avoid wearing blank NAND pages.
  echo "echo 'Step 4: writing UBI rootfs (this takes several minutes)...'"
  echo "nand write.trimffs ${UBI_MEM_ADDR} 0x1000000 ${UBI_SIZE}"
  echo "echo 'Step 4: UBI write done'"

  # fdtfile is set on every boot by misc_init_r() via get_spl_dt_name() from
  # the SPL header, so it does not need to be persisted.  CONFIG_ENV_IS_NOWHERE
  # means saveenv cannot write to NAND anyway.
  echo "echo 'Step 5: booting from NAND...'"
  echo "setenv fdtfile ${FDTFILE}"
  echo "echo '=== Flash complete — booting from NAND ==='"
  # Clear the script address so the next boot falls through to compiled-in NAND boot.
  echo "mw \${scriptaddr} 0x0"
  echo "boot"
} > "$UBOOT_SCRIPT_SRC"

mkimage -A arm -T script -C none -n "flash CHIP SkiffOS" \
  -d "$UBOOT_SCRIPT_SRC" "$UBOOT_SCRIPT" &>/dev/null
step_done

# ── Step 5: FEL upload and execute ──────────────────────────────────
echo ""
echo "Make sure the CHIP is in FEL mode:"
echo "  1. Power off and disconnect USB."
echo "  2. Bridge the FEL pin to GND."
echo "  3. Reconnect via micro-USB."
echo ""
read -p "Press ENTER to begin flashing..." -r

step "FEL upload"
# Two-phase FEL strategy:
#
# Phase 1 — sunxi-fel spl:
#   sunxi-fel spl writes the FEL re-entry magic before executing SPL, so
#   SPL detects it, initialises DRAM, and loops back into FEL mode.  We
#   use this FEL window to upload all images (including the 100+ MB UBI)
#   into DRAM while the USB is still live.
#
# Phase 2 — ARM trampoline at 0x40000000:
#   We cannot use "sunxi-fel uboot" here because that re-runs SPL a second
#   time, causing "DRAM: Timeout initialising DRAM" (controller already
#   active).  We also cannot jump directly to U-Boot with "sunxi-fel exe
#   0x4a000000" because the BROM does a raw jump leaving r0/r1/r2
#   undefined, and U-Boot crashes before printing anything to serial.
#
#   Instead, we write a 20-byte ARM trampoline to 0x40000000 that sets
#   r0=r1=r2=0 (ARM Linux boot convention) and then branches to U-Boot:
#
#     mov r0, #0          ; 00 00 a0 e3
#     mov r1, #0          ; 00 10 a0 e3
#     mov r2, #0          ; 00 20 a0 e3
#     ldr pc, [pc, #-4]   ; 04 f0 1f e5  (pc+8-4 = word below = 0x4a000000)
#     .word 0x4a000000    ; target address
#
#   USB disconnects when we execute the trampoline — that is expected.
#
# U-Boot runs CONFIG_BOOTCOMMAND: source ${scriptaddr} ; <inline NAND boot>
#   source finds the flash script at 0x43100000 and executes it.
#   The script writes SPL / U-Boot / UBI from DRAM to NAND, then boots.
echo "   Phase 1: booting SPL via FEL to initialise DRAM..."
$FEL spl "$IMAGES_DIR/sunxi-spl.bin"

echo "   Waiting for FEL USB to be ready after SPL DRAM init..."
FEL_READY=false
for i in $(seq 1 30); do
  if $FEL ver >/dev/null 2>&1; then
    FEL_READY=true
    echo "   FEL ready after ${i}s"
    break
  fi
  sleep 1
done
if [ "$FEL_READY" = false ]; then
  echo "ERROR: FEL USB did not become ready after 30 seconds."
  echo "       - Run 'lsusb | grep 1f3a' to check if device is still visible."
  echo "       - Ensure FEL pin is bridged before connecting USB."
  exit 1
fi
sleep 1

echo "   Uploading images to CHIP DRAM (FEL window):"
fel_write "$UBOOT_MEM_ADDR"        "$PADDED_UBOOT"
fel_write "$SPL_MEM_ADDR"          "$PADDED_SPL"
fel_write "$UBI_MEM_ADDR"          "$UBI_IMG"
fel_write "$UBOOT_SCRIPT_MEM_ADDR" "$UBOOT_SCRIPT"

echo "   Phase 2: writing ARM trampoline and jumping to U-Boot..."
TRAMPOLINE="$TMPDIR/trampoline.bin"
printf '\x00\x00\xa0\xe3' >  "$TRAMPOLINE"  # mov r0, #0
printf '\x00\x10\xa0\xe3' >> "$TRAMPOLINE"  # mov r1, #0
printf '\x00\x20\xa0\xe3' >> "$TRAMPOLINE"  # mov r2, #0
printf '\x04\xf0\x1f\xe5' >> "$TRAMPOLINE"  # ldr pc, [pc, #-4] -> 0x4a000000
printf '\x00\x00\x00\x4a' >> "$TRAMPOLINE"  # .word 0x4a000000
$FEL write 0x40000000 "$TRAMPOLINE"
echo "   Executing trampoline (USB will disconnect — U-Boot is starting)..."
$FEL exe 0x40000000
step_done

echo ""
echo "=== Flash initiated ==="
echo "The CHIP will erase and write its NAND. This takes 3-10 minutes."
echo "Watch the serial console for NAND activity, then power cycle when done."
echo ""
echo "After power cycling, the CHIP boots SkiffOS from NAND."
echo "  - rootfs volume (ubi0:rootfs): kernel, squashfs, skiff-init"
echo "  - persist volume (ubi0:persist): user data, expands to fill available NAND"
