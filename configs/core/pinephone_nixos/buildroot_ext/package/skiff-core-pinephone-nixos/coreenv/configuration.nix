{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/docker-image.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    (import <mobile-nixos/lib/configuration.nix> { device = "pine64-pinephone"; })
    # <mobile-nixos/examples/demo/configuration.nix>
    <mobile-nixos/examples/hello/configuration.nix>
    ./hardware-configuration.nix
  ];

  mobile.quirks.u-boot.additionalCommands = lib.mkForce "";
  mobile.boot.stage-1.kernel.package = lib.mkForce {};
  mobile.quirks.u-boot.package = lib.mkForce {};

  documentation.doc.enable = false;
  networking.firewall.enable = false;
  networking.interfaces.eth0.useDHCP = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.networkmanager.enable = false;
  networking.resolvconf.dnsExtensionMechanism = false;
  networking.useDHCP = false;
  networking.wireless.enable = false;
  security.audit.enable = false;
  security.sudo.enable = true;
  systemd.enableEmergencyMode = false;
  systemd.services.rescue.enable = false;

  boot.isContainer = true;
  boot.growPartition = false;
  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    bashInteractive
    cacert
    nix
    tree
    wget
    git
    gnupg
    curl
    tmux
    gnumake
    unzip
    vim
  ];           

  nixpkgs.config = {
    allowUnfree = true; # Allow "unfree" packages.

    # firefox.enableAdobeFlash = true;
    # chromium.enablePepperFlash = true;
  };

  environment.variables = { GOROOT = [ "${pkgs.go.out}/share/go" ]; };

  # don't set sycstl values in a container
  systemd.services.systemd-sysctl.restartTriggers = lib.mkForce [ ];
  environment.etc."sysctl.d/60-nixos.conf" = lib.mkForce { text = "# disabled\n"; };
  environment.etc."sysctl.d/50-default.conf" = lib.mkForce { text = "# diasbled\n"; };
  environment.etc."sysctl.d/50-coredump.conf" = lib.mkForce { text = "# disabled\n"; };
  boot.kernel.sysctl = lib.mkForce { };

  # add sudo group
  users.groups.sudo = {};
  security.sudo.extraRules = [
    { groups = [ "sudo" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];

  # add skiff core default user
  users.extraUsers.core = {
    isNormalUser = true;
    home = "/home/core";
    description = "Skiff Core";
    extraGroups = ["wheel" "vboxusers" "sudo"];
    createHome = true;
    shell = "/run/current-system/sw/bin/bash";
  };
}