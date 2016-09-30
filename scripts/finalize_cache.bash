#!/bin/bash
set -e

if [ -z "$CACHE_CONTEXT" ]; then
  echo "Set CACHE_CONTEXT and try again."
  exit 1
fi

if [ -z "$CACHE_PATH" ]; then
  echo "Set CACHE_PATH and try again."
  exit 1
fi

ARCHIVE=${CACHE_CONTEXT}-cache.tar.gz
HASHES=${CACHE_CONTEXT}-hashes.txt

if compare-cache $CACHE_PATH $HASHES ; then
  echo "No changes, continuing without uploading cache."
  exit 0
fi

echo "Re-packaging cache..."
if [ -f $ARCHIVE ]; then
  rm $ARCHIVE
fi
tar -czf $ARCHIVE -C $CACHE_PATH .

echo "Uploading cache..."
upload-cache $CACHE_CONTEXT $ARCHIVE
