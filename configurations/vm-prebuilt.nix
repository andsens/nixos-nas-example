{ inputs, ... }:
{
  imports = [
    inputs.qemu-vm.nixosModules.qemuSetup
    inputs.qemu-vm.nixosModules.qemuHardware
  ];
  config = {
    networking.hostName = "nas-prebuilt";
    networking.domain = "prebuilt.example.com";
    nas = {
      cluster.enable = true;
      nix.enable = true;
      services.enable = true;
      system = {
        boot.enable = true;
        filesystem.enable = true;
        networking.enable = true;
        networking.ipv6Prefix64 = "fd7a:e240:0e55:fe81";
        setup-secrets.enable = true;
      };
      user.enable = true;
    };
    system.stateVersion = "25.11";
    nixpkgs.hostPlatform = "x86_64-linux";
    users.users = {
      root.password = "test";
      admin.password = "test";
      admin.hashedPasswordFile = null;
    };
    boot.growPartition = true;
    systemd.repart.partitions."20-root".Encrypt = false;
    virtualisation = {
      diskSize = 50 * 1024;
      fileSystems."/".autoResize = true;
    };
  };
}
