# Temporary bridge: wraps the existing darwin configuration logic
# inside a flake-parts module. This will be decomposed in later phases.
#
# Reads from config.dotfiles.* (typed options) but reconstructs the old
# hostConfig/userConfig shapes for backward compatibility with existing
# darwin.nix, home.nix, and sub-modules.
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
  mkHostConfig = _hostKey: hostCfg: {
    inherit (hostCfg) system hostname;
    userConfig = {
      inherit (cfg.user) username fullName homeDirectory dotfilesPath;
    };
    userModule = ../home.nix;
    dock = {
      inherit (hostCfg.dock) persistent-apps;
    };
    homebrew = {
      inherit (hostCfg.homebrew) enableRosetta casks;
    };
  };

  # Collect all migrated darwin deferredModules
  darwinFeatureModules = builtins.attrValues config.flake.modules.darwin;

  mkDarwinConfig = hostConfig:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = {
        self = inputs.self;
        nixpkgs = inputs.nixpkgs;
        inherit hostConfig;
        inherit (hostConfig) userConfig;
      };
      modules =
        darwinFeatureModules
        ++ [
          ../darwin.nix
        inputs.mac-app-util.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.mac-app-util.homeManagerModules.default
              inputs.onepassword-shell-plugins.hmModules.default
            ];
            extraSpecialArgs = {
              inherit (hostConfig) userConfig hostname;
            };
            users.${hostConfig.userConfig.username} = import hostConfig.userModule;
          };
        }
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            inherit (hostConfig.homebrew) enableRosetta;
            user = hostConfig.userConfig.username;
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
