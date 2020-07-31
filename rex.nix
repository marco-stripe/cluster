{ config, pkgs, ... }:
let spotifydConf = pkgs.writeText "spotifyd.conf" "";
in {
  networking.hostName = "rex"; # Define your hostname.
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ./modules/qemu.nix
    # (<nixpkgs> + "/nixos/modules/services/cluster/k3s")
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.systemWide = true;

  # Unfortunately this doesn't work because the dynamic user used by this config doesn't get pulseaudio permissions :(
  # services.spotifyd.enable = true;

  systemd.services.spotifyd = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sound.target" ];
    description = "spotifyd, a Spotify playing daemon";
    serviceConfig = {
      ExecStart =
        "${pkgs.spotifyd}/bin/spotifyd --no-daemon --cache-path /var/cache/spotifyd --config-path ${spotifydConf}";
      Restart = "always";
      RestartSec = 12;
      User = "shairport";
      CacheDirectory = "spotifyd";
      SupplementaryGroups = [ "audio" ];
    };
  };

  services.shairport-sync = {
    enable = true;
    user = "shairport";
    arguments = "-v -o pa";
  };
  users.users.shairport = {
    extraGroups = [ "audio" ]; # Enable ‘sudo’ for the user.
  };

  networking.firewall.enable = false;
  networking.interfaces.wlp3s0.useDHCP = true;
  networking.wireless.interfaces = [ "wlp3s0" ];

  # TODO add ssh config to home-manager
  # Distributed Builds
  nix.buildMachines = [{
    hostName = "builder";
    system = "aarch64-linux";
    # if the builder supports building for multiple architectures, 
    # replace the previous line by, e.g.,
    # systems = ["x86_64-linux" "aarch64-linux"];
    maxJobs = 1;
    speedFactor = 2;
    supportedFeatures =
      [ "nixos-test" "benchmark" "big-parallel" ]; # kvm not supported :(
    mandatoryFeatures = [ ];
  }];

  nix.distributedBuilds = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernelModules = [ "br_netfilter" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };

  # services.k3s.enable = true;

  virtualisation.libvirtd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };
  programs.mosh.enable = true;

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

  networking.wireless.enable =
    true; # Enables wireless support via wpa_supplicant.

}
