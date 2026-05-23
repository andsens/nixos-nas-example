{
  inputs,
  lib,
  config,
  ...
}:
let
  clusterUserUIDInt = 900;
  clusterUserGIDInt = 900;
  clusterUserUID = toString clusterUserUIDInt;
  clusterUserGID = toString clusterUserGIDInt;
  userUID = toString config.users.users.${config.nas.user.username}.uid;
  userGID = toString config.users.groups.${config.nas.user.username}.gid;
in
{
  options.nas.cluster = {
    enable = lib.mkEnableOption "cluster module";
  };
  imports = [
    inputs.homelab.nixosModules.cluster
    inputs.homelab.nixosModules.cilium
    inputs.homelab.nixosModules.k8sss
    inputs.homelab.nixosModules.nfs-provisioner
    inputs.homelab.nixosModules.netutils
    ./cert-manager.nix
    ./external-dns.nix
  ];
  config = lib.mkIf config.nas.cluster.enable {
    users.users.cluster = {
      home = "/var/empty";
      createHome = false;
      shell = "/run/current-system/sw/bin/nologin";
      isSystemUser = true;
      uid = clusterUserUIDInt;
      group = "cluster";
    };
    users.groups.cluster = {
      name = "cluster";
      gid = clusterUserGIDInt;
    };
    homelab.nfs-provisioner = {
      enable = true;
      path = "/mnt/cluster/data";
      mountpointOwnership = {
        mode = "755";
        uid = clusterUserUIDInt;
        gid = clusterUserGIDInt;
      };
    };
    services.nfs.server = {
      enable = true;
      exports = ''
        ${config.homelab.nfs-provisioner.path} *(rw,root_squash,anonuid=${clusterUserUID},anongid=${clusterUserGID})
        /mnt/cluster/usenet *(rw,root_squash,anonuid=${clusterUserUID},anongid=${clusterUserGID})
        /mnt/cluster/torrents *(rw,root_squash,anonuid=${clusterUserUID},anongid=${clusterUserGID})
        /mnt/media/tvshows *(rw,all_squash,anonuid=${userUID},anongid=${userGID})
        /mnt/media/movies *(rw,all_squash,anonuid=${userUID},anongid=${userGID})
      '';
    };
    kubetree.service-macros = {
      runAsUser = clusterUserUIDInt;
      runAsGroup = clusterUserGIDInt;
      acmeProvider = "letsencrypt-production";
    };
    homelab.cilium = {
      enable = true;
      firewall.enable = true;
      lbCidr6 = "${config.nas.system.networking.ipv6Prefix64}:0:44::/112";
      cidr-groups = {
        enable = true;
        localLANCIDR4 = "10.15.188.0/24";
        localLANCIDR6 = "fd7a:e240:0e55:0::/64";
      };
    };
    homelab.netutils.enable = false;
    homelab.cluster = {
      enable = true;
      enableIPv4 = true;
      enableIPv6 = true;
      podCidr6 = "${config.nas.system.networking.ipv6Prefix64}:0:42::/96";
      svcCidr6 = "${config.nas.system.networking.ipv6Prefix64}:0:43::/112";
      dataDir = "/mnt/cluster/k3s";
    };
  };
}
