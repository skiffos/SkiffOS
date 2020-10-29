#!/bin/bash
set -eo pipefail

source /usr/local/etc/profile.d/nix.sh

NIX_MOBILE_VERSION=6675a044d57e6147490e472388e7b29dc9dc4d91
NIX_MOBILE_HASH=cac67777b96c830a45bc3e0f1ae3645ecee262dcca43d83d4fa782a4cf5861c6
NIX_MOBILE_SOURCE=https://github.com/NixOS/mobile-nixos/archive/${NIX_MOBILE_VERSION}/nixos-${NIX_MOBILE_VERSION}.tar.gz

echo "Downloading mobile-nixos version ${NIX_MOBILE_VERSION}..."
cd ~
wget -q -O mobile-nixos.tar.gz ${NIX_MOBILE_SOURCE}
DL_SUM=$(sha256sum mobile-nixos.tar.gz | cut -d" " -f1)
if [ $DL_SUM != $NIX_MOBILE_HASH ]; then
    echo "Downloaded file hash mismatch!"
    echo "URL: $NIX_MOBILE_SOURCE"
    echo "Got: $DL_SUM"
    echo "Expected: $NIX_MOBILE_HASH"
    exit 1
fi

mkdir -p nix-path/mobile-nixos
tar --strip-components=1 -C nix-path/mobile-nixos -xf ./mobile-nixos.tar.gz
rm mobile-nixos.tar.gz

# install nixos-mobile
export NIX_PATH=/home/builder/nix-path
cd /home/builder/sys-config
nix-build \
    --option sandbox false \
    -I mobile-nixos-configuration=$(pwd)/configuration.nix \
    -I mobile-nixos=$HOME/nix-path/mobile-nixos \
    -I nixpkgs=$HOME/nix-path/nixpkgs \
    -A config.system.build.toplevel \
    --argstr device pine64-pinephone \
    '<mobile-nixos>'

touch ./result/etc/NIXOS
mkdir -p ./result/etc/nixos/
cp configuration.nix hardware-configuration.nix ./result/etc/nixos/

cp -r $(pwd)/result/* /sys-root/
mkdir -p /sys-root/run/systemd/
mkdir -p /sys-root/root
rm result
