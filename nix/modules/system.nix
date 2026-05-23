{
  inputs,
  lib,
  config,
  ...
}:
{
  options.nas.system = {
    boot.enable = lib.mkEnableOption "default boot configuration";
    filesystem.enable = lib.mkEnableOption "default filesystem configuration";
    networking.enable = lib.mkEnableOption "default networking configuration";
    networking.ipv6Prefix64 = lib.mkOption {
      description = "IPv6 /64 prefix for the cluster network";
      type = lib.types.str;
    };
    setup-secrets.enable = lib.mkEnableOption "default setup-secrets configuration";
  };
  imports = [
    inputs.sbfde.nixosModules.default
    inputs.setup-secrets.nixosModules.default
  ];
  config = {
    time.timeZone = lib.mkDefault "Europe/Copenhagen";

    sbfde = lib.mkIf config.nas.system.boot.enable {
      enable = lib.mkDefault true;
      enrollEmptyKey = lib.mkDefault true;
      enrollFallbackPassword = lib.mkDefault true;
    };
    boot = lib.mkIf config.nas.system.boot.enable {
      loader.timeout = 0;
      initrd.systemd.enable = true;
    };

    systemd.repart.partitions = lib.mkIf config.nas.system.filesystem.enable {
      "10-esp".UUID = "629b20c9-4b60-4b73-bf95-fa3c524b6370";
      "20-root" = {
        Label = "nixos-nas";
        UUID = "ac059b4b-3a78-41dd-9123-2fae92c82231";
      };
    };
    networking = lib.mkIf config.nas.system.networking.enable {
      # Rejections make network troubleshooting *a lot* easier
      firewall.rejectPackets = true;
      useDHCP = true;
    };
    services = lib.mkIf config.nas.system.networking.enable {
      resolved.enable = true;
      avahi.enable = true;
      avahi.publish.enable = true;
    };
    setup-secrets = lib.mkIf config.nas.system.setup-secrets.enable {
      autoSetup = true;
      users.enable = true;
    };
    environment.systemPackages = lib.optional config.nas.system.setup-secrets.enable config.setup-secrets.script;
  };
}
