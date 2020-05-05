{ config, pkgs, ... }: {
  networking.hostName = "localnixos"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ./modules/qemu.nix
    ./nixpkgs/nixos/modules/services/cluster/k3s
  ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  nixpkgs = { overlays = [ (import ./overlays/k3s) ]; };

  networking.interfaces.enp0s5.useDHCP = true;
  # Use the GRUB 2 boot loader.

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernelModules = [ "br_netfilter" ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda"; # or "nodev" for efi only
    };
  };

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };

  services.k3s.enable = true;

  # virtualisation.libvirtd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryFlavor = "gnome3";
  };

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # Enable touchpad support.
  services.xserver.libinput.enable = true;
}
