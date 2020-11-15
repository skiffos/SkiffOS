{ config, pkgs, lib, ... }:

{
  # sound
  hardware.pulseaudio.enable = true;

  # ui
  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa_drivers;
  };

  services.xserver = {
    enable = true;
    layout = "us";
    videoDrivers = [ "modesetting" ];

    displayManager = {
      defaultSession = "xfce";
      lightdm.enable = true;
      lightdm.greeters.gtk = {
        theme.package = pkgs.nordic;
        theme.name = "Nordic";
      };
    };

    desktopManager.xfce.enable = true;
  };
}