# Host Assembly
# Builds darwinConfigurations from dotfiles.hosts options and collected
# feature modules. Each host gets all darwin and HM deferredModules plus
# per-host inline modules for dock, homebrew, and hostname overrides.
#
# No specialArgs or extraSpecialArgs — all values flow through the
# module system (flake-parts options or inline modules).
#
# See ADR-007 for the architecture overview.
{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles;

  # Collect all feature deferredModules
  darwinFeatureModules = builtins.attrValues config.flake.modules.darwin;
  hmFeatureModules = builtins.attrValues config.flake.modules.homeManager;

  mkDarwinConfig = _hostName: hostCfg:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (hostCfg) system;
      modules =
        darwinFeatureModules
        ++ [
          # Per-host dock persistent-apps override
          {
            system.defaults.dock.persistent-apps = lib.mkForce hostCfg.dock.persistent-apps;
          }
          # Per-host homebrew casks (list merge — appends to shared casks)
          {
            homebrew.casks = hostCfg.homebrew.casks;
          }
          inputs.mac-app-util.darwinModules.default
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules =
                hmFeatureModules
                ++ [
                  inputs.mac-app-util.homeManagerModules.default
                  inputs.onepassword-shell-plugins.hmModules.default
                  # Per-host: set dotfiles.hostname for 1password and others
                  {dotfiles.hostname = hostCfg.hostname;}
                ];
              users.${cfg.user.username} = {};
            };
          }
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              inherit (hostCfg.homebrew) enableRosetta;
              user = cfg.user.username;
              autoMigrate = true;
            };
          }
        ];
    };
in {
  flake.darwinConfigurations =
    lib.mapAttrs'
    (name: hostCfg:
      lib.nameValuePair hostCfg.hostname (mkDarwinConfig name hostCfg))
    cfg.hosts;

  flake.darwinPackages =
    inputs.self.darwinConfigurations.${cfg.hosts.personal.hostname}.pkgs;
}
