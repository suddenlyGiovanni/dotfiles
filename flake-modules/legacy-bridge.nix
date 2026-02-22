# Temporary bridge: wraps the existing darwin configuration logic
# inside a flake-parts module. This will be decomposed in later phases.
#
# See ADR-007 for the migration plan.
{inputs, ...}: let
  nix-darwin = inputs.nix-darwin;
  home-manager = inputs.home-manager;
  nix-homebrew = inputs.nix-homebrew;
  mac-app-util = inputs.mac-app-util;
  onepassword-shell-plugins = inputs.onepassword-shell-plugins;

  # Import host configurations
  personalHost = import ../hosts/personal.nix;
  workHost = import ../hosts/work.nix;

  # Helper function to create a darwin configuration
  mkDarwinConfig = hostConfig:
    nix-darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = {
        self = inputs.self;
        nixpkgs = inputs.nixpkgs;
        inherit hostConfig;
        inherit (hostConfig) userConfig;
      };
      modules = [
        ../darwin.nix
        mac-app-util.darwinModules.default
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              mac-app-util.homeManagerModules.default
              onepassword-shell-plugins.hmModules.default
            ];
            extraSpecialArgs = {
              inherit (hostConfig) userConfig hostname;
            };
            users.${hostConfig.userConfig.username} = import hostConfig.userModule;
          };
        }
        nix-homebrew.darwinModules.nix-homebrew
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
  flake = {
    darwinConfigurations = {
      ${personalHost.hostname} = mkDarwinConfig personalHost;
      ${workHost.hostname} = mkDarwinConfig workHost;
    };

    darwinPackages =
      inputs.self.darwinConfigurations.${personalHost.hostname}.pkgs;
  };
}
