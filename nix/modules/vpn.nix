{
  inputs,
  lib,
  config,
  ...
}:
{
  options.nas.vpn = {
    enable = lib.mkEnableOption "vpn module";
  };
  imports = [
    inputs.homelab.nixosModules.client-vpn
    inputs.homelab.nixosModules.privacy-vpn
  ];
  config = lib.mkIf config.nas.vpn.enable {
    networking.wireguard.enable = true;
    homelab.clientVPN = {
      enable = true;
      lbCidr6 = "${config.nas.system.networking.ipv6Prefix64}:0:45::/112";
      groups = {
        admins = {
          allowEgress = [
            "cluster"
            "local-lan"
          ];
          reservedIPs = [
            "10.45.0.1"
            "${config.nas.system.networking.ipv6Prefix64}:0:45:0:1"
          ];
          peers = [
            "IxpLCNrv6NDpZIREHHm95IdGcuT7cTIsb7d/YgpaGkA=" # Phone
            "Pbv4AYxd5qBarAaToaiwA05WL5o3GXHMW1z/YuGNDkk=" # Desktop
          ];
        };
      };
    };
    homelab.privacyVPN = {
      enable = true;
      clientIP4 = "10.2.0.2";
      clientIP6 = "2a07:b944::2:2";
      gatewayAddress = "172.30.248.34:51820";
      gatewayPublicKey = "0lARmb9WGqC3ub52lmjOHr94xV0Ex4ZDKcyxBmwJdkM=";
      gatewayIP4 = "10.2.0.1";
      gatewayIP6 = "2a07:b944::2:1";
    };
  };
}
