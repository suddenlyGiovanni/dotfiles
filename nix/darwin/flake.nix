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
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    ...
  }: let
    # Supported systems for formatter
    supportedSystems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Import host configurations
    personalHost = import ./hosts/personal.nix;
    workHost = import ./hosts/work.nix;

    # Helper function to create a darwin configuration
    mkDarwinConfig = hostConfig:
      nix-darwin.lib.darwinSystem {
        inherit (hostConfig) system;
        specialArgs = {
          inherit self nixpkgs hostConfig;
          inherit (hostConfig) userConfig;
        };
        modules = [
          ./configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit (hostConfig) userConfig;
              };
              users.${hostConfig.userConfig.username} = import hostConfig.userModule;
            };
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              inherit (hostConfig.homebrew) enableRosetta;

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

    # Formatter for `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
