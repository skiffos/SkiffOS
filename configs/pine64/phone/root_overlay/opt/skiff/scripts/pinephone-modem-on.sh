#!/bin/bash
set -eo pipefail

POWERED=/sys/class/modem-power/modem-power/device/powered

# Wait for modem to exist.
echo "Waiting for modem to exist..."
while [[ ! -e $POWERED ]]; do
    sleep 1
done

echo "Powering on Pinephone modem..."
echo 1 > $POWERED
