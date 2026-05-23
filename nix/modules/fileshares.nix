{
  inputs,
  lib,
  config,
  ...
}:
{
  options.nas.fileshares = {
    enable = lib.mkEnableOption "fileshares module";
  };
  imports = [ inputs.homelab.nixosModules.smb ];
  config = lib.mkIf config.nas.fileshares.enable {
    services.samba.enable = true;
    services.samba.settings = {
      "Movies" = {
        path = "/mnt/media/movies";
        writeable = true;
      };
      "TV Shows" = {
        path = "/mnt/media/tvshows";
        writeable = true;
      };
      "Bittorrent" = {
        path = "/mnt/cluster/torrents";
        writeable = true;
      };
      "Usenet" = {
        path = "/mnt/cluster/usenet";
        writeable = true;
      };
    };
  };
}
