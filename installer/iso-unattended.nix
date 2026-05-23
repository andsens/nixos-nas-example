{ ... }:
{
  imports = [
    ./iso.nix
  ];
  config = {
    networking.hostName = "installer";
    sbfde.installer.unattended = {
      enable = true;
      installDev = "/dev/vda";
      nixOSConfig = "nas-vm-installable";
    };
  };
}
