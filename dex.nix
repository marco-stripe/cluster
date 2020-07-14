{ config, pkgs, ... }: {
  networking.hostName = "dex"; # Define your hostname.
  imports = [ # Include the results of the hardware scan.
    ./modules/qemu.nix
    ./base-configuration.nix
  ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  # nixpkgs = { overlays = [ (import ./overlays/k3s) ]; };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp13s0.useDHCP = true;
  networking.interfaces.wlp0s26u1u2.useDHCP = true;
  networking.wireless.interfaces = [ "wlp0s26u1u2" ];

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };

  virtualisation.libvirtd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";

  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

}
