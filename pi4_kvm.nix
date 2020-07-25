# To build an installation:
# nix-build -j0 '<nixpkgs/nixos>' -A config.system -I nixos-config=/etc/nixos/cluster/pi4_kvm.nix -I nixpkgs=/home/marco/nixpkgs -I nixpkgs-overlays=/etc/nixos/cluster/overlays/rpi4 --argstr system aarch64-linux         
# To build on mac (Notice the 'ssh://builder aarch64-linux') this tells nix the
# machine is aarch64-linux
# nix-build -j0 '<nixpkgs/nixos>' -A config.system -I nixos-config=./pi4_kvm.nix -I nixpkgs=~/localnix/local-nixpkgs -I nixpkgs-overlays=./overlays/rpi4 --argstr system aarch64-linux --builders 'ssh://builder aarch64-linux'
#
# Updating the boot config:
# 1. nixos-rebuild test # Make sure the config works
# 2. cp -r /boot ~/boot-new # Backup just in case
# 3. rm -rf /boot/*
# 4. nixos-rebuild switch

{ config, pkgs, ... }:
let
  secrets = import ../secrets.nix;
  fast-honeycomb-reporter =
    (import ./fast-honeycomb-reporter.nix) { inherit pkgs; };
in {
  networking.hostName = "pi4"; # Define your hostname.
  imports = [ ./pi4_hardware_config.nix ./home-manager/nixos ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  nixpkgs = {
    overlays = [
      # (import ./overlays/k3s) 
      (import ./overlays/rpi4/rpi4-kvm.nix)
    ];
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
  networking.interfaces.eth0.useDHCP = true;
  networking.wireless.interfaces = [ "wlan0" ];

  environment.systemPackages =
    (with pkgs; [ home-manager wget vim git zsh fast-honeycomb-reporter ]);

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4_kvm;
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
        firmwareConfig = ''
          gpu_mem=192
        '';
      };
    };
  };

  # services.k3s.enable = true;

  networking.wireless.enable =
    true; # Enables wireless support via wpa_supplicant.

  nixpkgs.config.allowUnfree = true;

  nix.trustedUsers = [ "root" "marco" ];

  # Auto Upgrade with automatic reboots
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  networking.useDHCP = false;

  networking.wireless.networks = { "Dinner Plans" = { psk = secrets.wifi; }; };

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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJYbMiOSY6kaT7sZCDH5Uoifj+aniBvePenOr48q32N marco@st-marco1"
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
      "*/1 * * * *      root    . /etc/profile; cd /etc/nixos/cluster && git pull >> /tmp/cron.log 2>&1"
      "15 * * * *       marco  HONEYCOMB_API_KEY=${secrets.honeycomb_api_key} ${fast-honeycomb-reporter}/bin/fast-honeycomb-reporter >> /tmp/hc-reporter.log 2>&1"
    ];
  };

  hardware.bluetooth = {
    enable = true;
  };
  systemd.services.btattach = {
    before = [ "bluetooth.service" ];
    after = [ "dev-ttyAMA0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
    };
  };

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa_drivers;
  };
  hardware.deviceTree = {
    base = pkgs.device-tree_rpi;
    overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
  };

  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.lightdm = {
      enable = true;
      autoLogin = {
        enable = true;
        user = "marco";
      };
    };
    desktopManager = {
      xterm.enable = false;
      # plasma5.enable = true;
      xfce.enable = true;
    };

    # windowManager.i3.enable = true;
    videoDrivers = [ "fbdev" ];
  };

  hardware.enableRedistributableFirmware = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
