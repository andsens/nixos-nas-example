{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  sshKeyPath = "/etc/secrets.d/restic-default-ssh.key";
in
{
  options.nas.backup = {
    enable = lib.mkEnableOption "backup module";
  };
  imports = [ inputs.setup-secrets.nixosModules.default ];
  config = lib.mkIf config.nas.backup.enable {
    services.restic.backups.default = {
      repository = "sftp://u123456@u123456.your-storagebox.de/backup/";
      initialize = true;
      passwordFile = "/etc/secrets.d/restic-default-encryption.key";
      extraOptions = [
        "sftp.command='ssh -i ${sshKeyPath} u123456@u123456.your-storagebox.de -s sftp'"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    services.restic.backups.default.paths =
      config.homelab.cluster.backup.hostPaths
      ++ lib.flatten (
        lib.mapAttrsToList (
          namespace: spec:
          lib.flatten (
            lib.mapAttrsToList (
              pvName: paths:
              map (
                path:
                lib.removeSuffix "/" "${config.homelab.nfs-provisioner.path}/${namespace}-${pvName}/${lib.removePrefix "/" path}"
              ) paths
            ) spec
          )
        ) (config.homelab.cluster.backup.volumes)
      );
    setup-secrets = {
      sources.RESTIC_DEFAULT_PASSWORD = {
        description = "Encryption password for the restic default backup";
        cmd = ''${lib.getExe' pkgs.coreutils "cat"} "${config.services.restic.backups.default.passwordFile}"'';
      };
      sources.RESTIC_DEFAULT_SSH_KEY = {
        description = "SSH Key for the restic default backup location";
        cmd = ''${lib.getExe' pkgs.coreutils "cat"} "${sshKeyPath}"'';
      };
      destinations = [
        {
          logPrefix = "Restic default backup encryption password";
          requires = [ "RESTIC_DEFAULT_PASSWORD" ];
          cmd = ''printf "%s" "$RESTIC_DEFAULT_PASSWORD" >"${config.services.restic.backups.default.passwordFile}"'';
        }
        {
          logPrefix = "Restic default backup SSH Key";
          requires = [ "RESTIC_DEFAULT_SSH_KEY" ];
          cmd = ''
            umask 077
            printf "%s\n" "$RESTIC_DEFAULT_SSH_KEY" >"${sshKeyPath}"
          '';
        }
      ];
    };
  };
}
