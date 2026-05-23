{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  pushoverCreds = "/etc/secrets.d/pushover-credentials.env";
in
{
  options.nas.zfs = {
    enable = lib.mkEnableOption "enable zfs support";
  };
  imports = [ inputs.openzfs.nixosModules.default ];
  config = lib.mkIf config.nas.zfs.enable {
    openzfs = {
      enable = true;
      pools = {
        media = {
          autoDecrypt = true;
          autoMount = true;
        };
        cluster = {
          autoDecrypt = true;
          autoMount = true;
        };
      };
    };
    environment.systemPackages = [ pkgs.zfs ];
    networking.hostId = "7d01f71c"; # head -c 8 /etc/machine-id
    systemd.timers."zfs-scrub-monthly@cluster" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
    systemd.timers."zfs-trim-weekly@cluster" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
    systemd.timers."zfs-scrub-monthly@media" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
    systemd.timers."zfs-trim-weekly@media" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
    openzfs.zed.literalSettings = ''
      . "${pushoverCreds}"
    '';
    setup-secrets = {
      sources.ZED_PUSHOVER_USER = {
        description = "ZFS Event Daemon Pushover user";
        cmd = ''
          source "${pushoverCreds}"
          printf "%s" "$ZED_PUSHOVER_USER"
        '';
      };
      sources.ZED_PUSHOVER_TOKEN = {
        description = "ZFS Event Daemon Pushover token";
        cmd = ''
          source "${pushoverCreds}"
          printf "%s" "$ZED_PUSHOVER_TOKEN"
        '';
      };
      destinations = [
        {
          logPrefix = "ZFS Event Daemon Pushover credentials";
          requires = [
            "ZED_PUSHOVER_USER"
            "ZED_PUSHOVER_TOKEN"
          ];
          cmd = ''
            umask 077
            printf "ZED_PUSHOVER_USER=%q\nZED_PUSHOVER_TOKEN=%q\n" "$ZED_PUSHOVER_USER" "$ZED_PUSHOVER_TOKEN" >"${pushoverCreds}"
          '';
        }
      ];
    };
  };
}
