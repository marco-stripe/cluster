{ config, pkgs, ... }: {
  networking.hostName = "rusty"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
    ./modules/qemu.nix
  ];

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };

  nixpkgs.config.allowUnfree = true;

  nix.trustedUsers = [ "root" "marco" ];

  # Auto Upgrade with automatic reboots
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  security.sudo.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [ wget vim git zsh ];

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

}
