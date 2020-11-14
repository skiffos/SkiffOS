{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/docker-image.nix>
    ./skiff-core-nixos.nix
    ./hardware-configuration.nix
  ];
}