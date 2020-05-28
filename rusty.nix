{ config, pkgs, ... }: {
  networking.hostName = "rusty"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
    ./modules/qemu.nix
    ./base-configuration.nix
  ];

  # Allow aarch64 emulation with qemu
  qemu-user = {
    arm = true;
    aarch64 = true;
  };
}
