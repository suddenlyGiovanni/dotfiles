# Temporary bridge: wraps the existing darwin configuration logic
# inside a flake-parts module. This will be replaced by host-assembly.nix
# in Phase 10.
#
# Reads from config.dotfiles.* (typed options) and builds
# darwinConfigurations using migrated feature modules + per-host
# inline modules for dock persistent-apps and homebrew casks.
#
# hostConfig has been eliminated — dock and homebrew are now feature
# modules, with per-host overrides injected as inline darwin modules.
#
# See ADR-007 for the migration plan.
{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles;

  # Collect all migrated deferredModules
  darwinFeatureModules = builtins.attrValues config.flake.modules.darwin;
  hmFeatureModules = builtins.attrValues config.flake.modules.homeManager;

  mkDarwinConfig = hostName: hostCfg:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (hostCfg) system;
      specialArgs = {
        self = inputs.self;
        nixpkgs = inputs.nixpkgs;
      };
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
                ];
              extraSpecialArgs = {
                inherit (hostCfg) hostname;
              };
              users.${cfg.user.username} = {
                imports = [
                  ../programs # imports 1password (still uses hostname via extraSpecialArgs)
                ];
              };
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
