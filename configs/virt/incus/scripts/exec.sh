#!/bin/bash
set -e

command -v incus > /dev/null 2>&1 || {
  echo "Failed to find the incus command. Is incus installed on your host system?"
  exit 1
}

incus show skiff > /dev/null || {
  echo "Failed to find the skiff container. Did you execute \`make cmd/virt/incus/run\`?"
  exit 1
}

incus exec skiff -- sh
