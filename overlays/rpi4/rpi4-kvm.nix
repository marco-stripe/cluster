self: super: {
  linux_rpi4_kvm = super.linuxManualConfig {
    inherit (super) stdenv hostPlatform;
    inherit (linux_rpi4) src;
    version = "${linux_rpi4.version}-kvm";

    configfile = ../rpi4_kvm.config;
    allowImportFromDerivation = true;
  };
  linuxPackages_rpi4_kvm = super.linuxPackagesFor self.linux_rpi4_kvm;
}
