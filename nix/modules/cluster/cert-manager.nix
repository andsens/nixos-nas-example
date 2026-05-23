{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.setup-secrets.nixosModules.default
    inputs.homelab.nixosModules.cert-manager
  ];
  config = lib.mkIf config.nas.cluster.enable {
    setup-secrets = {
      sources.INWX_USERNAME = {
        description = "INWX Username";
        cmd = inputs.homelab.lib.setup-secrets.mkScript pkgs "getKubeSecret cert-manager inwx-credentials INWX_USERNAME";
      };
      sources.INWX_PASSWORD = {
        description = "INWX Password";
        cmd = inputs.homelab.lib.setup-secrets.mkScript pkgs "getKubeSecret cert-manager inwx-credentials INWX_PASSWORD";
      };
      destinations = [
        {
          logPrefix = "cert-manager (INWX Credentials)";
          requires = [
            "INWX_USERNAME"
            "INWX_PASSWORD"
          ];
          cmd = inputs.homelab.lib.setup-secrets.mkScript pkgs ''
            kubectl create secret generic -n cert-manager --dry-run=client inwx-credentials -oyaml \
              --from-literal=INWX_USERNAME="$INWX_USERNAME" \
              --from-literal=INWX_PASSWORD="$INWX_PASSWORD" | \
              kubectl apply -f -
          '';
        }
      ];
    };
    homelab.cert-manager.acme-staging-issuer.webhook-config = {
      provider = "inwx";
      secretName = "inwx-credentials";
    };
    homelab.cert-manager.acme-production-issuer.webhook-config = {
      provider = "inwx";
      secretName = "inwx-credentials";
    };
  };
}
