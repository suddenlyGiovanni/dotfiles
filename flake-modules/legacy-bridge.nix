# Temporary bridge: wraps the existing darwin configuration logic
# inside a flake-parts module. This will be decomposed in later phases.
#
# Reads from config.dotfiles.* (typed options) and reconstructs the old
# hostConfig shape for backward compatibility with remaining modules
# (dock, homebrew, 1password).
#
# userConfig has been eliminated -- darwin-core and home-core read
# directly from config.dotfiles.user via the closure technique.
#
# See ADR-007 for the migration plan.
{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles;

  # Reconstruct the legacy hostConfig shape from typed options
  # (still needed for dock, homebrew, and 1password hostname)
  mkHostConfig = _hostKey: hostCfg: {
    inherit (hostCfg) system hostname;
    dock = {
      inherit (hostCfg.dock) persistent-apps;
    };
    homebrew = {
      inherit (hostCfg.homebrew) enableRosetta casks;
    };
  };

  # Collect all migrated deferredModules
  darwinFeatureModules = builtins.attrValues config.flake.modules.darwin;
  hmFeatureModules = builtins.attrValues config.flake.modules.homeManager;

  mkDarwinConfig = hostConfig:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = {
        self = inputs.self;
        nixpkgs = inputs.nixpkgs;
        inherit hostConfig;
      };
      modules =
        darwinFeatureModules
        ++ [
          ../modules # imports dock.nix, homebrew.nix (still use hostConfig)
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
                inherit (hostConfig) hostname;
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
              inherit (hostConfig.homebrew) enableRosetta;
              user = cfg.user.username;
              autoMigrate = true;
            };
          }
        ];
    };
in {
  flake.darwinConfigurations =
    lib.mapAttrs'
    (name: hostCfg: let
      hostConfig = mkHostConfig name hostCfg;
    in
      lib.nameValuePair hostCfg.hostname (mkDarwinConfig hostConfig))
    cfg.hosts;

  flake.darwinPackages =
    inputs.self.darwinConfigurations.${cfg.hosts.personal.hostname}.pkgs;
}
