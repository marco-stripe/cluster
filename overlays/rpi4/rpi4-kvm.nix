self: super: {
  linux_rpi4_kvm_bak = super.linuxManualConfig {
    inherit (super) stdenv;
    inherit (super.linux_rpi4) src;
    version = "${super.linux_rpi4.version}-kvm";

    configfile = ./rpi4_kvm.config;
    allowImportFromDerivation = true;
  };
  linux_rpi4_kvm = super.linux_rpi4.override ({
    name = "linux_rpi4_kvm";
    extraConfig = ''
      CONFIG_HAVE_KVM_IRQCHIP y
      CONFIG_HAVE_KVM_IRQFD y
      CONFIG_HAVE_KVM_IRQ_ROUTING y
      CONFIG_HAVE_KVM_EVENTFD y
      CONFIG_KVM_MMIO y
      CONFIG_HAVE_KVM_MSI y
      CONFIG_HAVE_KVM_CPU_RELAX_INTERCEPT y
      CONFIG_KVM_VFIO y
      CONFIG_HAVE_KVM_ARCH_TLB_FLUSH_ALL y
      CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT y
      CONFIG_HAVE_KVM_IRQ_BYPASS y
      CONFIG_HAVE_KVM_VCPU_RUN_PID_CHANGE y
      CONFIG_IRQ_BYPASS_MANAGER y
      CONFIG_VIRTUALIZATION y
      CONFIG_KVM y
      CONFIG_KVM_ARM_HOST y
      CONFIG_KVM_INDIRECT_VECTORS y
      CONFIG_VHOST_CROSS_ENDIAN_LEGACY y
      CONFIG_PREEMPT_NOTIFIERS y
      CONFIG_MMU_NOTIFIER y
    '';
  });
  linuxPackages_rpi4_kvm = super.linuxPackagesFor self.linux_rpi4_kvm;
}
