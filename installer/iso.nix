{ inputs, modulesPath, ... }:
{
  imports = [
    inputs.sbfde.nixosModules.installer
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];
  config = {
    networking.hostName = "installer";
    system.stateVersion = "25.11";
    time.timeZone = "Europe/Copenhagen";
    nixpkgs.hostPlatform = "x86_64-linux";

    sbfde.installer = {
      enable = true;
      repoUrl = "git+ssh://git@github.com/andsens/nixos-nas-example";
      # This deploy key actually works
      deployKey = ''
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACDGe5DBjmOruPfvF288a6ttlHHm+yCJ0HzSLL3UW9YcgQAAAJipe2LVqXti
        1QAAAAtzc2gtZWQyNTUxOQAAACDGe5DBjmOruPfvF288a6ttlHHm+yCJ0HzSLL3UW9YcgQ
        AAAEARu2ikW8LOfhN/dZdzVhi9FSaXFulgpHQB+wbsHeeVIsZ7kMGOY6u49+8Xbzxrq22U
        ceb7IInQfNIsvdRb1hyBAAAADmFuZGVyc0BkZXNrdG9wAQIDBAUGBw==
        -----END OPENSSH PRIVATE KEY-----
      '';
    };
  };
}
