{ config, pkgs, ... }: {
  networking.hostName = "pi4"; # Define your hostname.
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ../hardware-configuration.nix
  ];

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
