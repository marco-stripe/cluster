self: super:

{
  k3s =
    self.callPackage ../../nixpkgs/pkgs/applications/networking/cluster/k3s { };
}
