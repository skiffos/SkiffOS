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

init-gce-creds
if ! download-cache $CACHE_CONTEXT $ARCHIVE ; then
  echo "Downloading cache failed, starting with empty dir."
  mkdir -p $CACHE_PATH
  touch $CACHE_PATH/keepme
else
  echo "Extracting cache..."
  tar -zxf $ARCHIVE -C $CACHE_PATH
  rm $ARCHIVE
fi

echo "Recording hashes..."
record-cache $TO_CACHE ${CACHE_CONTEXT}-hashes.txt
