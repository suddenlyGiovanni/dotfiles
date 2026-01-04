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
    # Define user configuration for personal machine
    personalUser = {
      username = "suddenlygiovanni";
      fullName = "Giovanni Ravalico";
      homeDirectory = "/Users/suddenlygiovanni";
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Giovannis-MacBook-Air
    darwinConfigurations."Giovannis-MacBook-Air" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit self;
        userConfig = personalUser;
      };
      modules = [
        ./configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            userConfig = personalUser;
          };
          home-manager.users.${personalUser.username} = import ./home.nix;
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = false;

            # User owning the Homebrew prefix
            user = personalUser.username;

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Giovannis-MacBook-Air".pkgs;
  };
}
