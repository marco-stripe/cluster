{ config, pkgs, ... }: {
  networking.hostName = "rusty"; # Define your hostname.
  networking.wireless.enable = false;
  imports = [ # Include the results of the hardware scan.
    ./home-manager/nixos
    ./modules/qemu.nix
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
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

  networking.nat.enable = true;
  networking.nat.externalInterface = "eth0";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    # Handled by GCP
    # allowedUDPPorts = [ 51820 ];

    # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
    # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
    extraCommands = ''
      iptables -t nat -A POSTROUTING -s 12.10.0.0/24 -o eth0 -j MASQUERADE
    '';
  };

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "12.10.0.1/24" ];

      # The port that Wireguard listens to. Must be accessible by the client.
      listenPort = 51820;

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "/root/wireguard-keys/private";

      peers = [
        # List of allowed peers.
        { # Feel free to give a meaning full name
          # Public key of the peer (not a file path).
          publicKey = "cU5OU0iEu05l0SXF0salb7CkkT16a7k3wA1CpAZMMk4";
          # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
          allowedIPs = [ "12.10.0.2/32" ];
        }
        # { # John Doe
        #   publicKey = "{john doe's public key}";
        #   allowedIPs = [ "10.100.0.3/32" ];
        # }
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
