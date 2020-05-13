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
      HAVE_KVM_IRQCHIP y
      HAVE_KVM_IRQFD y
      HAVE_KVM_IRQ_ROUTING y
      HAVE_KVM_EVENTFD y
      KVM_MMIO y
      HAVE_KVM_MSI y
      HAVE_KVM_CPU_RELAX_INTERCEPT y
      KVM_VFIO y
      HAVE_KVM_ARCH_TLB_FLUSH_ALL y
      KVM_GENERIC_DIRTYLOG_READ_PROTECT y
      HAVE_KVM_IRQ_BYPASS y
      HAVE_KVM_VCPU_RUN_PID_CHANGE y
      IRQ_BYPASS_MANAGER y
      VIRTUALIZATION y
      KVM y
      KVM_ARM_HOST y
      KVM_INDIRECT_VECTORS y
      VHOST_CROSS_ENDIAN_LEGACY y
      PREEMPT_NOTIFIERS y
      MMU_NOTIFIER y
    '';
  });
  linuxPackages_rpi4_kvm = super.linuxPackagesFor self.linux_rpi4_kvm;
}
