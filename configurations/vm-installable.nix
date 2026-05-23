{ inputs, ... }:
{
  imports = [
    inputs.qemu-vm.nixosModules.qemuHardware
  ];
  config = {
    networking.hostName = "nas-vm-install";
    networking.domain = "installable.example.com";
    nas = {
      cluster.enable = true;
      nix.enable = true;
      services.enable = true;
      system = {
        boot.enable = true;
        filesystem.enable = true;
        networking.enable = true;
        networking.ipv6Prefix64 = "fd7a:e240:0e55:fe80";
        setup-secrets.enable = true;
      };
      user.enable = true;
    };
    system.stateVersion = "25.11";
    nixpkgs.hostPlatform = "x86_64-linux";
    sbfde.includeInSelection = true;
    sbfde.enrollFallbackPassword = false;
    users.users = {
      root.password = "test";
      admin.password = "test";
      admin.hashedPasswordFile = null;
    };
  };
}
