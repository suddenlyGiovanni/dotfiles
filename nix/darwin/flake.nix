{
  description = "suddenlyGiovanni's darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = {
    self,
    nix-darwin,
    home-manager,
    nix-homebrew,
    ...
  }: let
    # Import host configurations
    personalHost = import ./hosts/personal.nix;
    workHost = import ./hosts/work.nix;

    # Helper function to create a darwin configuration
    mkDarwinConfig = hostConfig:
      nix-darwin.lib.darwinSystem {
        system = hostConfig.system;
        specialArgs = {
          inherit self;
          userConfig = hostConfig.userConfig;
        };
        modules = [
          ./configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              userConfig = hostConfig.userConfig;
            };
            home-manager.users.${hostConfig.userConfig.username} = import hostConfig.userModule;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = hostConfig.homebrew.enableRosetta;

              # User owning the Homebrew prefix
              user = hostConfig.userConfig.username;

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
        ];
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Giovannis-MacBook-Air
    # $ darwin-rebuild build --flake .#Work-MacBook
    darwinConfigurations = {
      ${personalHost.hostname} = mkDarwinConfig personalHost;
      ${workHost.hostname} = mkDarwinConfig workHost;
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations.${personalHost.hostname}.pkgs;
  };
}
