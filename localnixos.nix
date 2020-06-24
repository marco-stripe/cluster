{ config, pkgs, ... }:
let
  kubeMasterIP = "10.211.55.7";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 443;
in {
  networking.hostName = "localnixos"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ./modules/qemu.nix
    # ./nixpkgs/nixos/modules/services/cluster/k3s
  ];

  # Use k3s from the latest nixpkgs, but otherwise keep a stable system
  # nixpkgs = { overlays = [ (import ./overlays/k3s) ]; };

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

  # services.k3s.enable = true;

  virtualisation.libvirtd.enable = true;

  # Broken: see https://github.com/NixOS/nixpkgs/issues/79280
  # hardware.parallels.enable = true;

  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm = {
    enable = true;
    autoLogin = {
      enable = true;
      user = "marco";
    };
  };

  services.xserver.desktopManager.plasma5.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "us";

  ## Kubernetes

  # resolve master hostname
  # networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  # # packages for administration tasks
  # environment.systemPackages = with pkgs; [ kompose kubectl kubernetes ];

  # services.kubernetes = {
  #   roles = [ "master" "node" ];
  #   masterAddress = kubeMasterHostname;
  #   easyCerts = true;
  #   apiserver = {
  #     securePort = kubeMasterAPIServerPort;
  #     advertiseAddress = kubeMasterIP;
  #   };

  #   # use coredns
  #   addons.dns.enable = true;

  #   # needed if you use swap
  #   kubelet.extraOpts = "--fail-swap-on=false";
  # };
}
