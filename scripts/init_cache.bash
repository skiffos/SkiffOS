#!/bin/bash
set -e

if [ -d ~/.buildroot-ccache ]; then
  echo "Buildroot ccache already exists, skipping cache init."
  exit 0
fi

if [ -z "$CACHE_CONTEXT" ]; then
  echo "Set CACHE_CONTEXT and try again."
  exit 1
fi

init-gce-creds
if ! download-cache $CACHE_CONTEXT; then
  echo "Downloading cache failed, starting with empty ccache."
  mkdir -p ~/.
else
  echo "Extracting cache..."
  tar -zxf build-cache.tar.gz
  rm build-cache.tar.gz
fi

echo "Recording hashes..."
record-cache ~/.buildroot-ccache/
