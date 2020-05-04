args@{ config, pkgs, ... }:
let base = (import ./base-configuration.nix args);
in base // {
  imports = [ # Include the results of the hardware scan.
    ../hardware-configuration.nix
  ];
  networking.hostName = "pi4"; # Define your hostname.

  environment.systemPackages = base.environment.systemPackages
    ++ (with pkgs; [ home-manager ]);

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
  };

}
