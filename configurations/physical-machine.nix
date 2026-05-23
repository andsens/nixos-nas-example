{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    networking.hostName = "nas";
    networking.domain = "example.com";
    nas = {
      backup.enable = true;
      cluster.enable = true;
      fileshares.enable = true;
      nix.enable = true;
      services.enable = true;
      system = {
        boot.enable = true;
        filesystem.enable = true;
        networking.enable = true;
        networking.ipv6Prefix64 = "fd7a:e240:0e55:cafe";
        setup-secrets.enable = true;
      };
      user.enable = true;
      vpn.enable = true;
      zfs.enable = true;
    };
    system.stateVersion = "25.05";
    hardware.enableRedistributableFirmware = true;
    nixpkgs.hostPlatform = "x86_64-linux";

    environment.systemPackages = [ pkgs.smartmontools ];
    sbfde.includeInSelection = true;
    # Spin down disks after 10 min. of inactivity
    services.udev.extraRules = lib.concatStringsSep "\n" ([
      (lib.concatStringsSep ", " [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -B 600 -S 6 /dev/%k"''
      ])
    ]);
    boot = {
      kernelParams = [ "consoleblank=60" ];
      loader.systemd-boot.configurationLimit = 120;
      blacklistedKernelModules = [ "r8169" ];
      initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "sd_mod"
      ];
      initrd.kernelModules = [ ];
      kernelModules = [
        "kvm-amd"
        "r8125" # Gigabyte NIC driver
        "it87" # Gigabyte Fan control
      ];
      extraModulePackages = [
        config.boot.kernelPackages.r8125
        config.boot.kernelPackages.it87
      ];
      extraModprobeConfig = ''
        options it87 ignore_resource_conflict=1 force_id=0x8622
      '';
    };
    hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
  };
}
