{ config, pkgs, ... }: {
  networking.hostName = "pi4"; # Define your hostname.
  imports = [ ./base-configuration.nix ];
  # ./nixpkgs/nixos/modules/services/cluster/k3s ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  nixpkgs = {
    overlays =
      [ (import ./overlays/k3s) (import ./overlays/rpi4/rpi4-kvm.nix) ];
  };

  networking.interfaces.wlan0.useDHCP = true;
  networking.wireless.interfaces = [ "wlan0" ];

  environment.systemPackages = (with pkgs; [ home-manager ]);

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4_kvm;
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
  };

  # services.k3s.enable = true;

  networking.wireless.enable =
    true; # Enables wireless support via wpa_supplicant.
}
