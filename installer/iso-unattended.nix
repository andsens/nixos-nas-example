{ ... }:
{
  imports = [
    ./iso.nix
  ];
  config = {
    networking.hostName = "installer";
    sbfde.installer.unattended = {
      enable = true;
      installDev = "/dev/vdb";
      nixOSConfig = "nas-vm-installable";
    };
  };
}
