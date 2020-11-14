{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/docker-image.nix>
    ./skiff-core-nixos.nix
    ./skiff-core-nixos-xfce.nix
    ./hardware-configuration.nix
  ];
}