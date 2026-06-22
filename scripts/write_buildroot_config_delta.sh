#!/bin/bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <baseline-config> <edited-config> <output-fragment>" >&2
  exit 2
fi

baseline_config=$1
edited_config=$2
output_fragment=$3

delta_config=$(mktemp)
cleanup() {
  rm -f "$delta_config"
}
trap cleanup EXIT

diffconfig="${BUILDROOT_DIR:-}/utils/diffconfig"
if [ -n "${BUILDROOT_DIR:-}" ] && [ -f "$diffconfig" ]; then
  if [ -x "$diffconfig" ]; then
    "$diffconfig" -m "$baseline_config" "$edited_config" > "$delta_config"
  else
    python3 "$diffconfig" -m "$baseline_config" "$edited_config" > "$delta_config"
  fi
else
  python3 - "$baseline_config" "$edited_config" > "$delta_config" <<'PY'
import sys


def read_config(path):
    values = {}
    with open(path, encoding="utf-8") as config_file:
        for raw_line in config_file:
            line = raw_line.strip()
            if not line:
                continue
            if line.startswith("# ") and line.endswith(" is not set"):
                values[line[2:-11]] = "n"
                continue
            if line.startswith("#") or "=" not in line:
                continue
            name, value = line.split("=", 1)
            values[name] = value
    return values


def format_config(name, value):
    if value == "n":
        return f"# {name} is not set"
    return f"{name}={value}"


baseline = read_config(sys.argv[1])
edited = read_config(sys.argv[2])

for name in sorted(edited):
    if baseline.get(name) != edited[name]:
        print(format_config(name, edited[name]))
PY
fi

if [ -s "$delta_config" ]; then
  mkdir -p "$(dirname "$output_fragment")"
  cp "$delta_config" "$output_fragment"
  echo "Saved Buildroot menuconfig delta to $output_fragment"
elif [ -f "$output_fragment" ]; then
  rm "$output_fragment"
  echo "Removed empty Buildroot menuconfig delta at $output_fragment"
else
  echo "No Buildroot menuconfig delta to save."
fi
