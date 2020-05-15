# To build an installation:
# nix-build -j0 '<nixpkgs/nixos>' -A config.system -I nixos-config=/etc/nixos/cluster/pi4_kvm.nix -I nixpkgs=/home/marco/nixpkgs -I nixpkgs-overlays=/etc/nixos/cluster/overlays/rpi4 --argstr system aarch64-linux         
# To build on mac (Notice the 'ssh://builder aarch64-linux') this tells nix the
# machine is aarch64-linux
# nix-build -j0 '<nixpkgs/nixos>' -A config.system -I nixos-config=./pi4_kvm.nix -I nixpkgs=~/localnix/local-nixpkgs -I nixpkgs-overlays=./overlays/rpi4 --argstr system aarch64-linux --builders 'ssh://builder aarch64-linux'
#
# Updating the boot config:
# 1. umount /boot
# 2. nixos-rebuild switch
# 3. cp -r /boot ~/boot-new
# 4. mount /dev/mmcblk0p1 /boot
# 5. rm -rf /boot/*
# 6. mv ~/boot-new/* /boot/

{ config, pkgs, ... }: {
  networking.hostName = "pi4"; # Define your hostname.
  imports = [
    ./pi4_hardware_config.nix
    ./home-manager/nixos
    ./nixpkgs/nixos/modules/services/cluster/k3s
  ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  nixpkgs = {
    overlays =
      [ (import ./overlays/k3s) (import ./overlays/rpi4/rpi4-kvm.nix) ];
  };

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

  networking.interfaces.wlan0.useDHCP = true;
  networking.wireless.interfaces = [ "wlan0" ];

  environment.systemPackages = (with pkgs; [ home-manager wget vim git zsh ]);

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

  services.k3s.enable = true;

  networking.wireless.enable =
    true; # Enables wireless support via wpa_supplicant.

  nixpkgs.config.allowUnfree = true;

  nix.trustedUsers = [ "root" "marco" ];

  # Auto Upgrade with automatic reboots
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  networking.useDHCP = false;

  networking.wireless.networks = {
    "07d931_5g" = { psk = "***REMOVED***"; };
  };

  security.sudo.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    publish.domain = true;
    publish.addresses = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };

  users.users.marco = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "libvirtd" ]; # Enable ‘sudo’ for the user.
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPs7qqifLNNLNvjBKmsgTefmxLO0tstGBfZ4BXv3KmDn marcomunizaga@marco-mbp"
    ];
  };
  programs.zsh.enable = true;

  programs.command-not-found.enable = false;
  programs.bash.interactiveShellInit = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';

  home-manager.users.marco = import ./home/home.nix;

  # Pull configuration from github every 5 minutes
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/1 * * * *      root    . /etc/profile; cd /etc/nixos/cluster && git pull >> /tmp/cron.log  2>&1"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
