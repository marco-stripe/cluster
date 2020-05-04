{ config, pkgs, ... }: {
  networking.hostName = "rex"; # Define your hostname.
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ./modules/qemu.nix
    ./nixpkgs/nixos/modules/services/cluster/k3s
  ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  nixpkgs = { overlays = [ (import ./overlays/k3s) ]; };

  networking.interfaces.wlp3s0.useDHCP = true;
  networking.wireless.interfaces = [ "wlp3s0" ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };

  services.k3s.enable = true;

  virtualisation.libvirtd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.illum.enable = true;
  services.logind.lidSwitchExternalPower = "ignore";
  services.logind.lidSwitch = "ignore";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # Enable touchpad support.
  services.xserver.libinput.enable = true;

}
