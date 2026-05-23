{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nas.services = {
    enable = lib.mkEnableOption "services module";
  };
  imports = [ inputs.homelab.nixosModules.services ];
  config = lib.mkIf config.nas.services.enable {
    nas.nix.allowUnfreePkgs =
      with pkgs;
      map lib.getName [
        plexRaw
        unrar
      ];
    homelab.services = {
      homepage.enable = true;
      plex = {
        enable = true;
        volumes."/mnt/media/movies".nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/media/movies";
        };
        volumes."/mnt/media/tvshows".nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/media/tvshows";
        };
        reservedIPs = [
          "10.44.0.20"
          "${config.nas.system.networking.ipv6Prefix64}:0:44:0:14"
        ];
      };
      actualbudget = {
        enable = true;
        importSchedule = "0,30 8-23 * * *";
        importConfig = {
          lunchFlowBaseUrl = "https://lunchflow.app/api/v1";
          budgetSyncId = "09c1cdc8-6036-4ceb-a02b-669ace321ffd";
          accountMappings = [
            {
              lunchFlowAccountId = 1234;
              lunchFlowAccountName = "Private";
              actualBudgetAccountId = "b4531513-4c67-4593-9ee2-53f8bd0abeae";
              actualBudgetAccountName = "Private";
              syncStartDate = "2026-01-01";
            }
          ];
        };
      };
      ghostfolio = {
        enable = true;
        importSchedule = "5,35 8-23 * * *";
        actualBudgetSyncId = "09c1cdc8-6036-4ceb-a02b-669ace321ffd";
        actualBudgetSyncMap = {
          Private = "Private";
        };
      };
      flood.enable = true;
      rtorrent = {
        enable = true;
        downloadsVolume.nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/cluster/torrents";
        };
      };
      sabnzbd = {
        enable = true;
        downloadsVolume.nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/cluster/usenet";
        };
      };
      sonarr = {
        enable = true;
        volumes."/mnt/media/tvshows".nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/media/tvshows";
        };
      };
      radarr = {
        enable = true;
        volumes."/mnt/media/movies".nfs = {
          server = "${config.networking.hostName}.${config.homelab.cluster.domain}";
          path = "/mnt/media/movies";
        };
      };
      prowlarr.enable = true;
      metrics-server.enable = true;
      mimir.enable = true;
      grafana.enable = true;
      alloy.enable = true;
      node-exporter.enable = true;
      smartctl-exporter.enable = true;
      zfs-exporter.enable = true;
    };
  };
}
