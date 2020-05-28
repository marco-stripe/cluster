{ config, pkgs, ... }: {
  networking.hostName = "rusty"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    ./base-configuration.nix
    ./modules/qemu.nix
  ];

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };
}
