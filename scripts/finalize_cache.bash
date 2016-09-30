#!/bin/bash
set -e

if [ -z "$CACHE_CONTEXT" ]; then
  echo "Set CACHE_CONTEXT and try again."
  exit 1
fi

if [ ! -f ./cache_hashes.txt ]; then
  echo "No cache hashes, cannot finalize."
  exit 1
fi

if compare-cache ~/.buildroot-ccache/; then
  echo "No changes, continuing without uploading cache."
  exit 0
fi

echo "Re-packaging cache..."
if [ -f build-cache.tar.gz ]; then
  rm build-cache.tar.gz
fi
tar -czf build-cache.tar.gz ~/.buildroot-ccache/

echo "Uploading cache..."
upload-cache $CACHE_CONTEXT
