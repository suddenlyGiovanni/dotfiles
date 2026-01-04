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
    # Supported systems for devShell
    supportedSystems = ["aarch64-darwin" "x86_64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    # Import host configurations
    personalHost = import ./hosts/personal.nix;
    workHost = import ./hosts/work.nix;

    # Helper function to create a darwin configuration
    mkDarwinConfig = hostConfig:
      nix-darwin.lib.darwinSystem {
        inherit (hostConfig) system;
        specialArgs = {
          inherit self hostConfig;
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

    # Development shell for working on this configuration
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "dotfiles-dev";
        packages = with pkgs; [
          # Nix tools
          nixd # Nix language server
          alejandra # Nix formatter
          statix # Nix linter
          deadnix # Find dead code in Nix
          nil # Another Nix LSP

          # Utilities
          just # Task runner
        ];

        shellHook = ''
          echo "dotfiles development shell"
          echo ""
          echo "Available commands:"
          echo "  alejandra .      - Format all Nix files"
          echo "  statix check .   - Lint Nix files"
          echo "  deadnix .        - Find unused code"
          echo "  darwin-rebuild switch --flake . - Apply configuration"
          echo ""
        '';
      };
    });
  };
}
