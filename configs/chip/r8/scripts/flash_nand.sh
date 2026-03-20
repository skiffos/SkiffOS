#!/bin/bash
# Flash SkiffOS to C.H.I.P. internal NAND via USB FEL mode.
#
# Works on BOTH Hynix and Toshiba NAND variants. The two variants
# differ only in OOB spare-area size; "nand slc-mode on" normalises
# behaviour for both by forcing pseudo-SLC operation.
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
# ── CHIP NAND in pseudo-SLC mode ──────────────────────────────────
#  Physical page:           16 KiB  (0x4000)
#  Physical erase block:     4 MiB  (0x400000)
#  Effective EB (SLC mode):  2 MiB  (0x200000)  — half of MLC
#  UBIFS LEB:      2 MiB – 2×16 KiB = 2 064 384 bytes
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
for tool in sunxi-fel mkfs.ubifs ubinize mkimage rsync; do
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

source "${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh"

# ── memory addresses for FEL upload ──
SPL_MEM_ADDR=0x43000000
UBOOT_MEM_ADDR=0x4a000000
UBOOT_SCRIPT_MEM_ADDR=0x43100000
UBI_MEM_ADDR=0x44000000   # 64 MiB into DRAM; CHIP has 512 MiB total

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

PADDED_SPL="$TMPDIR/sunxi-padded-spl"
PADDED_UBOOT="$TMPDIR/padded-uboot"
PADDED_UBOOT_SIZE=0xc0000     # 768 KiB reserved for U-Boot area
UBOOT_SCRIPT_SRC="$TMPDIR/uboot.cmds"
UBOOT_SCRIPT="$TMPDIR/uboot.scr"

# ── Step 1: prepare SPL ────────────────────────────────────────────
# The BROM can only read 8 KiB per 16 KiB NAND page; pad each chunk
# with random data to improve MLC wear distribution.
echo "=== Preparing SPL ==="
SPL="$IMAGES_DIR/sunxi-spl.bin"
dd if="$SPL"         of="$PADDED_SPL" bs=8k count=1 skip=0 conv=sync
dd if=/dev/urandom   of="$PADDED_SPL" bs=8k count=1 seek=1 conv=sync
dd if="$SPL"         of="$PADDED_SPL" bs=8k count=1 skip=1 seek=2 conv=sync
dd if=/dev/urandom   of="$PADDED_SPL" bs=8k count=1 seek=3 conv=sync
dd if="$SPL"         of="$PADDED_SPL" bs=8k count=1 skip=2 seek=4 conv=sync
dd if=/dev/urandom   of="$PADDED_SPL" bs=8k count=1 seek=5 conv=sync
PADDED_SPL_SIZE=$(stat --printf="%s" "$PADDED_SPL" | xargs printf "0x%08x")

# ── Step 2: prepare U-Boot ────────────────────────────────────────
echo "=== Preparing U-Boot ==="
UBOOT="$IMAGES_DIR/u-boot-dtb.bin"
dd if="$UBOOT" of="$PADDED_UBOOT" bs=16k conv=sync
UBOOT_FILE_SIZE=$(stat --printf="%s" "$PADDED_UBOOT" | xargs printf "0x%08x")
REMAINING_PAGES=$(( (PADDED_UBOOT_SIZE - UBOOT_FILE_SIZE) / 0x4000 ))
dd if=/dev/urandom of="$PADDED_UBOOT" seek=$((UBOOT_FILE_SIZE / 0x4000)) \
   bs=16k count="$REMAINING_PAGES" conv=sync 2>/dev/null || true

# ── Step 3: build UBIFS + UBI image ─────────────────────────────────
# The UBI volume mirrors the SD card /boot/ layout so skiff-init works.
echo "=== Building UBIFS image ==="

NAND_ROOT="$TMPDIR/nand-root"
mkdir -p "$NAND_ROOT/boot/skiff-init"

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
    -d "$NAND_ROOT/boot/boot.txt" "$NAND_ROOT/boot/boot.scr"
fi

# Warn if image may be too large to fit in CHIP's available RAM
# (CHIP has 512 MiB; UBI_MEM_ADDR is at +64 MiB, leaving ~448 MiB)
ROOTFS_SIZE=$(du -sb "$NAND_ROOT" | awk '{print $1}')
MAX_FEL_SIZE=$(( 448 * 1024 * 1024 ))
if [ "$ROOTFS_SIZE" -gt "$MAX_FEL_SIZE" ]; then
  echo ""
  echo "WARNING: SkiffOS image (~$(( ROOTFS_SIZE / 1024 / 1024 )) MiB) may exceed"
  echo "         CHIP's available RAM for FEL upload (~448 MiB)."
  echo "         Consider using a smaller core config."
  echo ""
fi

ROOTFS_UBIFS="$TMPDIR/chip-rootfs.ubifs"
mkfs.ubifs \
  --min-io-size=16384 \
  --leb-size=2064384  \
  --max-leb-cnt=4096  \
  --root="$NAND_ROOT"  \
  --output="$ROOTFS_UBIFS"

# Build persist UBIFS — pre-formatted empty volume; autoresize fills remaining NAND on first boot.
echo "=== Building persist UBIFS image ==="
PERSIST_DIR="$TMPDIR/persist-root"
mkdir -p "$PERSIST_DIR"
PERSIST_UBIFS="$TMPDIR/chip-persist.ubifs"
mkfs.ubifs \
  --min-io-size=16384 \
  --leb-size=2064384  \
  --max-leb-cnt=4096  \
  --root="$PERSIST_DIR" \
  --output="$PERSIST_UBIFS"

UBINIZE_CFG="$TMPDIR/ubinize.cfg"
cat > "$UBINIZE_CFG" << 'EOF'
[rootfs]
mode=ubi
image=ROOTFS_UBIFS_PLACEHOLDER
vol_id=0
vol_type=dynamic
vol_name=rootfs

[persist]
mode=ubi
image=PERSIST_UBIFS_PLACEHOLDER
vol_id=1
vol_type=dynamic
vol_name=persist
vol_flags=autoresize
EOF
sed -i "s|ROOTFS_UBIFS_PLACEHOLDER|$ROOTFS_UBIFS|" "$UBINIZE_CFG"
sed -i "s|PERSIST_UBIFS_PLACEHOLDER|$PERSIST_UBIFS|" "$UBINIZE_CFG"

UBI_IMG="$TMPDIR/chip-nand.ubi"
ubinize \
  --output="$UBI_IMG"  \
  --min-io-size=16384  \
  --peb-size=2097152   \
  --sub-page-size=16384 \
  "$UBINIZE_CFG"

UBI_SIZE=$(stat --printf="%s" "$UBI_IMG" | xargs printf "0x%08x")
echo "UBI image size: $UBI_SIZE"

# ── Step 4: build U-Boot flash script ────────────────────────────────
echo "=== Preparing U-Boot NAND flash script ==="
{
  if [ "$NAND_ERASE_BB" = true ]; then
    echo "nand scrub -y 0x0 0x200000000"
  else
    echo "nand erase 0x0 0x200000000"
  fi

  echo "sunxi_nand config spl"
  # Write SPL to 8 × 1 MiB locations for redundancy (worn-block tolerance)
  for offset in 0x0 0x100000 0x200000 0x300000 0x400000 0x500000 0x600000 0x700000; do
    echo "nand write ${SPL_MEM_ADDR} ${offset} ${PADDED_SPL_SIZE}"
  done
  echo "sunxi_nand config default"

  # Write U-Boot at 8 MiB
  echo "nand write ${UBOOT_MEM_ADDR} 0x800000 ${PADDED_UBOOT_SIZE}"

  # Enable pseudo-SLC mode — handles BOTH Hynix and Toshiba NAND
  echo "nand slc-mode on"
  echo "nand write.trimffs ${UBI_MEM_ADDR} 0x1000000 ${UBI_SIZE}"

  # Boot from NAND (board has no SD card slot)
  echo "setenv fdtfile sun5i-r8-chip.dtb"
  echo "setenv condev 'console=ttyS0,115200n8 console=tty1'"
  echo "setenv skiff_nand_boot 'nand slc-mode on; mtdparts; ubi part UBI; ubifsmount ubi0:rootfs; ubifsload \${fdt_addr_r} /boot/\${fdtfile}; ubifsload \${kernel_addr_r} /boot/zImage; setenv bootargs ubi.mtd=2 root=ubi0:rootfs rootfstype=ubifs rw init=/boot/skiff-init/skiff-init-squashfs \${condev} net.ifnames=0; bootz \${kernel_addr_r} - \${fdt_addr_r}'"
  echo "setenv bootcmd 'run skiff_nand_boot'"
  echo "saveenv"
  echo "mw \${scriptaddr} 0x0"
  echo "boot"
} > "$UBOOT_SCRIPT_SRC"

mkimage -A arm -T script -C none -n "flash CHIP SkiffOS" \
  -d "$UBOOT_SCRIPT_SRC" "$UBOOT_SCRIPT"

# ── Step 5: FEL upload and execute ──────────────────────────────────
echo ""
echo "=== Ready to flash. Make sure the CHIP is in FEL mode ==="
echo "    (FEL pin jumpered to GND, CHIP connected via micro-USB)"
echo ""
read -p "Press ENTER to begin flashing..." -r

echo "Uploading SPL to SRAM..."
$FEL spl "$SPL"

echo "Waiting 1s for DRAM initialisation..."
sleep 1

echo "Uploading images to RAM..."
$FEL write "$SPL_MEM_ADDR"          "$PADDED_SPL"
$FEL write "$UBOOT_MEM_ADDR"        "$PADDED_UBOOT"
$FEL write "$UBI_MEM_ADDR"          "$UBI_IMG"
$FEL write "$UBOOT_SCRIPT_MEM_ADDR" "$UBOOT_SCRIPT"

echo "Executing U-Boot to start NAND flash..."
echo "(Monitor the CHIP's UART at 115200 baud to see progress.)"
$FEL exe "$UBOOT_MEM_ADDR"

echo ""
echo "=== Flash initiated ==="
echo "The CHIP will erase and write its NAND, then reboot automatically."
echo "This takes 3-10 minutes. Do not disconnect power."
echo ""
echo "After flashing, the CHIP boots SkiffOS from NAND."
echo "  - rootfs volume (ubi0:rootfs): kernel, squashfs, skiff-init"
echo "  - persist volume (ubi0:persist): user data, expands to fill available NAND"
