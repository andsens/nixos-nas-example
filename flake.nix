{
  description = "nixos-nas";
  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qemu-vm = {
      url = "github:andsens/nixos-qemu-vm";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    sbfde = {
      url = "github:andsens/nixos-sbfde";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lanzaboote.follows = "lanzaboote";
      inputs.flake-parts.follows = "flake-parts";
      inputs.qemu-vm.follows = "qemu-vm";
    };
    openzfs = {
      url = "github:andsens/nixos-openzfs";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.setup-secrets.follows = "setup-secrets";
    };
    homelab = {
      url = "github:andsens/nixos-homelab";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.setup-secrets.follows = "setup-secrets";
      inputs.kubetree.follows = "kubetree";
      inputs.k8sss.follows = "k8sss";
    };
    kubetree = {
      url = "github:andsens/nix-kubetree";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    setup-secrets = {
      url = "github:andsens/nixos-setup-secrets";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    k8sss = {
      url = "github:andsens/k8sss";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    {
      systems,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        flake-parts-lib,
        self,
        inputs,
        lib,
        ...
      }:
      {
        systems = import systems;
        flake = rec {
          nixosModules = {
            backup = ./nix/modules/backup.nix;
            cluster = ./nix/modules/cluster;
            fileshares = ./nix/modules/fileshares.nix;
            nix = ./nix/modules/nix.nix;
            services = ./nix/modules/services.nix;
            system = ./nix/modules/system.nix;
            user = ./nix/modules/user.nix;
            vpn = ./nix/modules/vpn.nix;
            zfs = ./nix/modules/zfs.nix;
          };
          nixosConfigurations =
            let
              allModules = map (name: self.nixosModules.${name}) (builtins.attrNames nixosModules);
              specialArgs = { inherit self inputs; };
            in
            {
              nas = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [ ./configurations/physical-machine.nix ] ++ allModules;
              };
              nas-vm-installable = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [ ./configurations/vm-installable.nix ] ++ allModules;
              };
              nas-vm-prebuilt = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [ ./configurations/vm-prebuilt.nix ] ++ allModules;
              };
              iso = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [
                  ./installer/iso.nix
                  { sbfde.installer.isoNixOSConfigurationName = "iso"; }
                ];
              };
              iso-unattended = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [
                  ./installer/iso-unattended.nix
                  { sbfde.installer.isoNixOSConfigurationName = "iso-unattended"; }
                ];
              };
              installer-vm = nixpkgs.lib.nixosSystem {
                specialArgs = specialArgs;
                modules = [ ./installer/vm.nix ];
              };
            };
        };
        perSystem =
          {
            system,
            pkgs,
            lib,
            ...
          }:
          {
            apps =
              let
                shell = cmd: lib.getExe (pkgs.writeShellScriptBin "run" cmd);
                workspace = "/home/user/Workspace";
                localFlakes = {
                  homelab = "git+file://${workspace}/nixos-homelab";
                  k8sss = "git+file://${workspace}/k8sss";
                  kubetree = "git+file://${workspace}/nix-kubetree";
                  openzfs = "git+file://${workspace}/nixos-openzfs";
                  qemu-vm = "git+file://${workspace}/nixos-qemu-vm";
                  sbfde = "git+file://${workspace}/nixos-sbfde";
                  setup-secrets = "git+file://${workspace}/nixos-setup-secrets";
                };
                nasUser = self.nixosConfigurations.nas.config.nas.user.username;
                nasAddr = "${self.nixosConfigurations.nas.config.networking.hostName}.${self.nixosConfigurations.nas.config.networking.domain}";
              in
              {
                deploy.program = shell ''
                  ${lib.getExe pkgs.nixos-rebuild} \
                    --use-remote-sudo\
                    --target-host "${nasUser}@${nasAddr}" \
                    --build-host "${nasUser}@${nasAddr}" \
                    --flake "${workspace}/nixos-nas#nas" \
                    switch'';
                diff.program = shell ''
                  exec ${lib.getExe pkgs.nix-diff} \
                    "$(readlink result)" \
                    "$(nix build --no-link --print-out-paths '.#nixosConfigurations.nas.config.system.build.toplevel')"'';
                update.program = shell "exec ${lib.getExe pkgs.nix} flake update --allow-dirty-locks ${
                  lib.escapeShellArgs (
                    lib.flatten (
                      lib.mapAttrsToList (name: url: [
                        "--override-input"
                        name
                        url
                        name
                      ]) localFlakes
                    )
                  )
                }";
              };
            packages = {
              container-utils = import ./packages/container-utils pkgs;
            }
            // (lib.mapAttrs (name: spec: inputs.qemu-vm.lib.mkVMRunner spec) {
              nas = {
                inherit system;
                vmName = "nas-vm";
                nixosConfiguration = self.nixosConfigurations.nas-vm-prebuilt;
              };
              installer = {
                inherit system;
                vmName = "installer-vm";
                nixosConfiguration = self.nixosConfigurations.installer-vm;
              };
            });
          };
      }
    );
}
