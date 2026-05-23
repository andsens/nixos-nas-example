{ self, inputs, ... }:
{
  imports = [
    inputs.qemu-vm.nixosModules.qemuHardware
    inputs.qemu-vm.nixosModules.qemuSetup
    inputs.sbfde.nixosModules.vm
  ];
  config = {
    system.stateVersion = "25.11";
    nixpkgs.hostPlatform = "x86_64-linux";
    sbfde.vm.isoImage = self.nixosConfigurations.iso-unattended.config.sbfde.installer.isoImage;
  };
}
