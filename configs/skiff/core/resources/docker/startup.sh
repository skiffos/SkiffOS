#!/bin/sh
set -eo pipefail
touch /.container_startup_in_progress

echo " --> initializing skiff core..."

if [ -f /core-startup.sh ]; then
  chmod +x /core-startup.sh
  /core-startup.sh
fi

# Compat fix for mosh and screen
chown root:adm /dev/ptmx || true
chmod 777 /dev/ptmx || true

# Remove the lock file
rm /.container_startup_in_progress

echo " --> setup done, sleeping forever"
tail -f /dev/null
