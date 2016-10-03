#!/bin/bash

pushd /etc/systemd/network
NETWORK_FILES=$(ls *.network)
for i in "${NETWORK_FILES[@]}"; do
  if DESTINATION=$(cat $i | grep -m1 "Destination" | cut -d= -f2); then
    echo "Adding route to ${DESTINATION}..."
    ip route add to $DESTINATION dev eth0 scope link proto static metric 10
  fi
done
