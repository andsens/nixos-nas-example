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
    inputs.homelab.nixosModules.external-dns
  ];
  config = lib.mkIf config.nas.cluster.enable {
    setup-secrets.destinations = [
      {
        logPrefix = "external-dns (INWX Credentials)";
        requires = [
          "INWX_USERNAME"
          "INWX_PASSWORD"
        ];
        cmd = inputs.homelab.lib.setup-secrets.mkScript pkgs ''
          kubectl create secret generic -n external-dns --dry-run=client inwx-credentials -oyaml \
            --from-literal=INWX_USERNAME="$INWX_USERNAME" \
            --from-literal=INWX_PASSWORD="$INWX_PASSWORD" | \
            kubectl apply -f -
        '';
      }
    ];
    kubetree.resources.external-dns.deployment.spec.servicePodSpec = {
      mainContainer.envByName = {
        EXTERNAL_DNS_PROVIDER = "webhook";
        EXTERNAL_DNS_MIN_TTL = "300s";
      };
      containersByName.external-dns-node-source.envByName = {
        EXTERNAL_DNS_PROVIDER = "webhook";
        EXTERNAL_DNS_MIN_TTL = "300s";
      };
      containersByName.external-dns-libdns-webhook = {
        name = "external-dns-libdns-webhook";
        image = "ghcr.io/orbit-online/external-dns-libdns-webhook:0.3.0";
        args = [
          "--provider.name=inwx"
          "--provider.zones=${config.homelab.cluster.domain}"
        ];
        securityContext = {
          runAsGroup = 65534;
          runAsUser = 65534;
          allowPrivilegeEscalation = false;
          readOnlyRootFilesystem = true;
          capabilities.add = [ "NET_BIND_SERVICE" ];
          capabilities.drop = [ "ALL" ];
        };
        envByName = {
          INWX_USERNAME.valueFrom.secretKeyRef = {
            name = "inwx-credentials";
            key = "INWX_USERNAME";
          };
          INWX_PASSWORD.valueFrom.secretKeyRef = {
            name = "inwx-credentials";
            key = "INWX_PASSWORD";
          };
          LIBDNS_WEBHOOK_LISTEN = ":8888";
          LIBDNS_PROVIDER_CONFIG = "{\n  \"Username\": \"$(INWX_USERNAME)\",\n  \"Password\": \"$(INWX_PASSWORD)\"\n}\n";
        };
        portsByName.api = 8888;
        livenessProbe.httpGet = {
          path = "/healthz";
          port = 8888;
        };
        readinessProbe.httpGet = {
          path = "/healthz";
          port = 8888;
        };
      };
    };
  };
}
