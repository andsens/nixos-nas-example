{
  lib,
  config,
  ...
}:
let
  cfg = config.nas.user;
in
{
  options.nas.user = {
    enable = lib.mkEnableOption "user module";
    username = lib.mkOption {
      description = "Username of the primary user";
      type = lib.types.str;
      default = "admin";
    };
  };
  config = lib.mkIf config.nas.user.enable {
    services.openssh.enable = lib.mkDefault true;
    security = {
      sudo.enable = lib.mkDefault true;
      sudo.wheelNeedsPassword = lib.mkDefault false;
      polkit.enable = lib.mkDefault true;
    };
    users = {
      mutableUsers = lib.mkDefault false;
      allowNoPasswordLogin = lib.mkDefault true;
      users.${cfg.username} = {
        isNormalUser = true;
        uid = 1000;
        group = cfg.username;
        hashedPasswordFile = lib.mkDefault "/etc/secrets.d/${cfg.username}.pwhash";
        extraGroups = [
          "wheel"
          "networkmanager"
          # Nixos would normally expect the users primary group to be `users`, so let's make sure we add the user back into the group.
          "users"
        ];
        openssh.authorizedKeys.keys = [ ];
      };
      groups.${cfg.username} = {
        name = lib.mkDefault cfg.username;
        gid = lib.mkDefault 1000;
      };
    };
  };
}
